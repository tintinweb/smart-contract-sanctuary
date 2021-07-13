// SPDX-License-Identifier: MIT

import "BEP20Base.sol";
import "Ownable.sol";
import "ISwapV2.sol";
import "IEcosystem.sol";

pragma solidity ^0.8.6;

contract BabyBoxer is BEP20Base, Ownable {
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _oOwned;
    mapping(address => Index) private _excludeList;
    uint256 private _rTotal;
    address[] private _excludeListStorage;
    Swap[] private _swapQueue;
    bool private _inSwap;
    address[] private _sellPath;
    address private constant _swapRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; 
    address private constant _deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public constant ecosystemAddress = 0x05Bb50D8c1D4061630563AD63e72Fe6d0229427c;
    address public constant _marketingAddress = 0x77Cd27Af9B668A6065B171a5354C1cF209011bAb;
    ISwapRouterV2 public swapRouter;
    address public swapPair;

    event AddedToExcludeList(address account);
    event RemovedFromExcludeList(address account);
    event Claim(address account, uint256 accumulatedAmount);
    event EcosystemContribution(uint256 amount);
    event MarketingContribution(uint256 amount);
    event LiquidityContribution(
        uint256 amount,
        uint256 swappedAmount,
        uint256 receivedBNB
    );

    struct Index {
        bool contains;
        uint256 index;
    }
    struct RValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rReflectionFee;
        uint256 rOtherFees;
    }
    struct TValues {
        uint256 tTransferAmount;
        uint256 tReflectionFee;
        uint256 tOtherFees;
    }
    struct Values {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rReflectionFee;
        uint256 rOtherFees;
        uint256 tTransferAmount;
        uint256 tReflectionFee;
        uint256 tOtherFees;
    }
    struct Swap {
        uint256 id;
        uint256 amount;
    }

    modifier lockSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor() BEP20Base("BabyBoxer", "BBoxer", 9, 888888888888888 * 10**9) {
        ISwapRouterV2 _swapRouter = ISwapRouterV2(_swapRouterAddress);
        swapRouter = _swapRouter;
        swapPair = ISwapV2Factory(_swapRouter.factory()).createPair(
            address(this),
            _swapRouter.WETH()
        );
        _sellPath = [address(this), _swapRouter.WETH()];

        addToExcludeList(_marketingAddress);
        addToExcludeList(ecosystemAddress);
        addToExcludeList(address(this));
        addToExcludeList(_deadAddress);
        addToExcludeList(_msgSender());

        _rTotal = ~uint256(0) - (~uint256(0) % (888888888888888 * 10**9));
        _rOwned[_msgSender()] += _rTotal;
        _balances[_msgSender()] += 888888888888888 * 10**9;
        emit Transfer(address(0), _msgSender(), 888888888888888 * 10**9);
    }

    receive() external payable {}

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (isExcluded(account)) return _balances[account];
        return _tokenFromReflection(_rOwned[account]);
    }

    function isExcluded(address account) public view returns (bool) {
        return _excludeList[account].contains;
    }

    function addToExcludeList(address account) public onlyOwner {
        require(!isExcluded(account), "BEP20: Account is not excluded");
        require(account != swapPair, "BEP20: You can't exclude swap pair");
        require(
            account != _swapRouterAddress,
            "BEP20: You can't exclude swap router"
        );
        require(_excludeListStorage.length <= 10, "BEP20: You can't exclude more than 10 addresses");

        _excludeListStorage.push(account);
        _excludeList[account].contains = true;
        _excludeList[account].index = _excludeListStorage.length - 1;
        if (_rOwned[account] > 0) {
            _balances[account] = _tokenFromReflection(_rOwned[account]);
        }
        emit AddedToExcludeList(account);
    }

    function removeFromExcludeList(address account) public onlyOwner {
        require(isExcluded(account), "BEP20: Account is excluded");
        require(
            account != address(this),
            "You can't remove contract address from exclude list"
        );
        require(
            account != _deadAddress,
            "You can't remove dead address from exclude list"
        );
        require(
            account != ecosystemAddress,
            "BEP20: You can't remove bridge ecosystem from exclude list"
        );

        _excludeList[_excludeListStorage[_excludeListStorage.length - 1]]
        .index = _excludeList[account].index;
        _excludeListStorage[_excludeList[account].index] = _excludeListStorage[
            _excludeListStorage.length - 1
        ];
        _excludeListStorage.pop();
        _excludeList[account].contains = false;
        _balances[account] = 0;
        emit RemovedFromExcludeList(account);
    }

    function getAccumulatedAmount(address account)
        public
        view
        returns (uint256)
    {
        return balanceOf(account) - _oOwned[account];
    }

    function claimAccumulatedAmount(address[] memory path) public lockSwap {
        uint256 accumulatedAmount = getAccumulatedAmount(_msgSender());
        require(
            accumulatedAmount > 0,
            "BEP20: accumulated amount must be greater than 0"
        );

        _oOwned[_msgSender()] = balanceOf(_msgSender());
        _transfer(_msgSender(), address(this), accumulatedAmount);
        _swapContractTokensForBNB(_msgSender(), path, accumulatedAmount);
        emit Claim(_msgSender(), accumulatedAmount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "BEP20: amount must be greater than 0");

        if (sender != swapPair && !_inSwap) {
            uint256 contractBalance = balanceOf(address(this));
            if (contractBalance > 0) {
                _swapAndDistribute(contractBalance);
            }
        }

        bool takeFee = !(isExcluded(sender) || isExcluded(recipient));
        Values memory values = _getValues(amount, takeFee);

        if (isExcluded(sender))
            if (isExcluded(recipient))
                _transferBothExcluded(sender, recipient, amount, values);
            else _transferFromExcluded(sender, recipient, amount, values);
        else if (isExcluded(recipient))
            _transferToExcluded(sender, recipient, values);
        else _transferStandard(sender, recipient, values);

        if (amount <= _oOwned[sender]) _oOwned[sender] -= amount;
        else _oOwned[sender] = 0;
        _oOwned[recipient] += values.tTransferAmount;

        if (takeFee) _distributeFees(values);
    }

    function _swapAndDistribute(uint256 amount) private lockSwap {
        if (_swapQueue.length == 0) {
            uint256 ecosystemFee = amount / 2;
            uint256 marketingFee = amount / 4;
            uint256 liquidityFee = amount / 4;

            if (!IEcosystem(ecosystemAddress).isWhitelisted(address(this))) {
                liquidityFee += ecosystemFee;
                ecosystemFee = 0;
            } else {
                _swapQueue.push(Swap(1, ecosystemFee));
            }
            _swapQueue.push(Swap(2, marketingFee));
            _swapQueue.push(Swap(3, liquidityFee));
        }

        Swap memory currentSwap = _swapQueue[_swapQueue.length - 1];
        if (currentSwap.id == 1) // ecosystem swap
        {
            _swapContractTokensForBNB(ecosystemAddress, _sellPath, currentSwap.amount);
            emit EcosystemContribution(currentSwap.amount);
        } else if (currentSwap.id == 2) // marketing swap
        {
            _swapContractTokensForBNB(_marketingAddress, _sellPath, currentSwap.amount);
            emit MarketingContribution(currentSwap.amount);
        } else if (currentSwap.id == 3) // liquidity swap
        {
            uint256 half = currentSwap.amount / 2;
            uint256 initialBalance = address(this).balance;
            _swapContractTokensForBNB(address(this), _sellPath, half);
            uint256 receivedBNB = address(this).balance - initialBalance;
            _approve(address(this), _swapRouterAddress, half);
            swapRouter.addLiquidityETH{value: receivedBNB}(
                address(this),
                half,
                0,
                0,
                address(0),
                block.timestamp
            );
            emit LiquidityContribution(currentSwap.amount, half, receivedBNB);
        }
        _swapQueue.pop();
    }

    function _swapContractTokensForBNB(address recipient, address[] memory path, uint256 amount)
        private
    {
        _approve(address(this), _swapRouterAddress, amount);
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, // slippage is unavoidable
            path,
            recipient,
            block.timestamp + 5 minutes
        );
    }

    function _transferStandard(
        address sender,
        address recipient,
        Values memory values
    ) private {
        _rOwned[sender] -= values.rAmount;
        _rOwned[recipient] += values.rTransferAmount;
        emit Transfer(sender, recipient, values.tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        Values memory values
    ) private {
        _rOwned[sender] -= values.rAmount;
        _balances[recipient] += values.tTransferAmount;
        _rOwned[recipient] += values.rTransferAmount;
        emit Transfer(sender, recipient, values.tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        Values memory values
    ) private {
        _balances[sender] -= tAmount;
        _rOwned[sender] -= values.rAmount;
        _rOwned[recipient] += values.rTransferAmount;
        emit Transfer(sender, recipient, values.tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        Values memory values
    ) private {
        _balances[sender] -= tAmount;
        _rOwned[sender] -= values.rAmount;
        _balances[recipient] += values.tTransferAmount;
        _rOwned[recipient] += values.rTransferAmount;
        emit Transfer(sender, recipient, values.tTransferAmount);
    }

    function _getValues(uint256 tAmount, bool deductReflectionFee)
        private
        view
        returns (Values memory)
    {
        TValues memory tValues = _getTValues(tAmount, deductReflectionFee);
        RValues memory rValues = _getRValues(
            tAmount,
            tValues.tReflectionFee,
            tValues.tOtherFees
        );

        return
            Values(
                rValues.rAmount,
                rValues.rTransferAmount,
                rValues.rReflectionFee,
                rValues.rOtherFees,
                tValues.tTransferAmount,
                tValues.tReflectionFee,
                tValues.tOtherFees
            );
    }

    function _getTValues(uint256 tAmount, bool deductReflectionFee)
        private
        pure
        returns (TValues memory)
    {
        if (!deductReflectionFee) return TValues(tAmount, 0, 0);

        uint256 tReflectionFee = (tAmount * 2) / 100;
        uint256 tOtherFees = (tAmount * 8) / 100;
        uint256 tTransferAmount = tAmount - tReflectionFee - tOtherFees;
        return TValues(tTransferAmount, tReflectionFee, tOtherFees);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tReflectionFee,
        uint256 tOtherFees
    ) private view returns (RValues memory) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount * currentRate;
        uint256 rReflectionFee = tReflectionFee * currentRate;
        uint256 rOtherFees = tOtherFees * currentRate;
        uint256 rTransferAmount = rAmount - rReflectionFee - rOtherFees;
        return RValues(rAmount, rTransferAmount, rReflectionFee, rOtherFees);
    }

    function _getRate() private view returns (uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _totalSupply;
        for (uint256 i = 0; i < _excludeListStorage.length; i++) {
            if (
                _rOwned[_excludeListStorage[i]] > rSupply ||
                _balances[_excludeListStorage[i]] > tSupply
            ) return _rTotal / _totalSupply;
            rSupply -= _rOwned[_excludeListStorage[i]];
            tSupply -= _balances[_excludeListStorage[i]];
        }
        if (rSupply < _rTotal / _totalSupply) return _rTotal / _totalSupply;
        return rSupply / tSupply;
    }

    function _tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function _distributeFees(Values memory values) private {
        _rTotal -= values.rReflectionFee;
        _rOwned[address(this)] += values.rOtherFees;
        _balances[address(this)] += values.tOtherFees;
    }
}