// SPDX-License-Identifier: UNLICENSE

/**
About TattooMoney DeFi project:

We are creating a

https://app.TattooMoney.io/ - Our App
https://TattooMoney.io/ - Info about Project
*/

import "./owned.sol";
import "./interfaces.sol";

pragma solidity 0.8.7;

contract TattooMoneyV2 is IERC20, Owned {
    constructor(address _owner) {
        (uint256 rAmount, , , , , , ) = _getValues(INITIAL_SUPPLY);
        _rOwned[_owner] = rAmount;
        emit Transfer(ZERO, _owner, INITIAL_SUPPLY);
        owner = _owner;
    }

    string public constant name = "TattooMoney";
    string public constant symbol = "TAT2";
    uint8 public constant decimals = 6;

    uint256 private constant MAX = type(uint256).max;
    uint256 private constant INITIAL_SUPPLY = 1_000_000_000 * (10**decimals);
    uint256 private constant BURN_STOP_SUPPLY = INITIAL_SUPPLY / 10;
    uint256 private _tTotal = INITIAL_SUPPLY;
    uint256 private _rTotal = (MAX - (MAX % INITIAL_SUPPLY));
    uint256 private _tFeeTotal;

    address private constant ZERO = address(0);
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) public override allowance;

    mapping(address => bool) public isFeeFree;

    mapping(address => bool) public isExcluded;
    address[] private _excluded;

    // ERC20 totalSupply
    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    /// Total fees collected
    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    // ERC20 balanceOf
    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        if (isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    // ERC20 transfer
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // ERC20 approve
    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // ERC20 transferFrom
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 amt = allowance[sender][msg.sender];
        require(amt >= amount, "ERC20: transfer amount exceeds allowance");
        // reduce only if not permament allowance (uniswap etc)
        if (amt < MAX) {
            allowance[sender][msg.sender] -= amount;
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    // ERC20 increaseAllowance
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            allowance[msg.sender][spender] + addedValue
        );
        return true;
    }

    // ERC20 decreaseAllowance
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        require(
            allowance[msg.sender][spender] >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(
            msg.sender,
            spender,
            allowance[msg.sender][spender] - subtractedValue
        );

        return true;
    }

    // ERC20 burn
    function burn(uint256 amount) external {
        require(msg.sender != ZERO, "ERC20: burn from the zero address");
        (uint256 rAmount, , , , , , ) = _getValues(amount);
        _burn(msg.sender, amount, rAmount);
    }

    // ERC20 burnFrom
    function burnFrom(address account, uint256 amount) external {
        require(account != ZERO, "ERC20: burn from the zero address");
        require(
            allowance[account][msg.sender] >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        allowance[account][msg.sender] -= amount;
        (uint256 rAmount, , , , , , ) = _getValues(amount);
        _burn(account, amount, rAmount);
    }

    /**
        Burn tokens into fee (aka airdrop)
        @param tAmount number of tokens to destroy
     */
    function reflect(uint256 tAmount) external {
        address sender = msg.sender;
        require(
            !isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , , ) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _rTotal -= rAmount;
        _tFeeTotal += tAmount;
    }

    /**
        Reflection amount for given amount of token, can deduct fees
        @param tAmount number of tokens to transfer
        @param deductTransferFee true or false
        @return amount reflection amount
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        external
        view
        returns (uint256 amount)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            //rAmount
            (amount, , , , , , ) = _getValues(tAmount);
        } else {
            //rTransferAmount
            (, amount, , , , , ) = _getValues(tAmount);
        }
    }

    /**
        Calculate number of tokens by current reflection rate
        @param rAmount reflected amount
        @return number of tokens
     */
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
        return rAmount / currentRate;
    }

    /**
        Internal approve function, emit Approval event
        @param _owner approving address
        @param spender delegated spender
        @param amount amount of tokens
     */
    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) private {
        require(_owner != ZERO, "ERC20: approve from the zero address");
        require(spender != ZERO, "ERC20: approve to the zero address");

        allowance[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    /**
        Internal transfer function, calling feeFree if needed
        @param sender sender address
        @param recipient destination address
        @param tAmount transfer amount
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        require(sender != ZERO, "ERC20: transfer from the zero address");
        require(recipient != ZERO, "ERC20: transfer to the zero address");
        if (tAmount > 0) {
            if (isFeeFree[sender]) {
                _feeFreeTransfer(sender, recipient, tAmount);
            } else {
                (
                    uint256 rAmount,
                    uint256 rTransferAmount,
                    uint256 rFee,
                    uint256 rBurn,
                    uint256 tTransferAmount,
                    uint256 tFee,
                    uint256 tBurn
                ) = _getValues(tAmount);

                _rOwned[sender] -= rAmount;
                if (isExcluded[sender]) {
                    _tOwned[sender] -= tAmount;
                }
                _rOwned[recipient] += rTransferAmount;
                if (isExcluded[recipient]) {
                    _tOwned[recipient] += tTransferAmount;
                }

                _reflectFee(rFee, tFee);
                if (tBurn > 0) {
                    _reflectBurn(rBurn, tBurn, sender);
                }
                emit Transfer(sender, recipient, tTransferAmount);
            }
        } else emit Transfer(sender, recipient, 0);
    }

    /**
        Function provide fee-free transfer for selected addresses
        @param sender sender address
        @param recipient destination address
        @param tAmount transfer amount
     */
    function _feeFreeTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (uint256 rAmount, , , , , , ) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        if (isExcluded[sender]) {
            _tOwned[sender] -= tAmount;
        }
        _rOwned[recipient] += rAmount;
        if (isExcluded[recipient]) {
            _tOwned[recipient] += tAmount;
        }
        emit Transfer(sender, recipient, tAmount);
    }

    /// reflect fee amounts in global values
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal -= rFee;
        _tFeeTotal += tFee;
    }

    /// reflect burn amounts in global values
    function _reflectBurn(
        uint256 rBurn,
        uint256 tBurn,
        address account
    ) private {
        _rTotal -= rBurn;
        _tTotal -= tBurn;
        emit Transfer(account, ZERO, tBurn);
    }

    /// calculate reflect values for given transfer amount
    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 rBurn,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tBurn
        )
    {
        tFee = tAmount / 100; //1% transfer fee
        tTransferAmount = tAmount - tFee;
        if (_tTotal > BURN_STOP_SUPPLY) {
            tBurn = tAmount / 200; //0.5% burn fee
            if (_tTotal < BURN_STOP_SUPPLY + tBurn) {
                tBurn = _tTotal - BURN_STOP_SUPPLY;
            }
            tTransferAmount -= tBurn;
        }
        uint256 currentRate = _getRate();
        rAmount = tAmount * currentRate;
        rFee = tFee * currentRate;
        rTransferAmount = rAmount - rFee;
        if (tBurn > 0) {
            rBurn = tBurn * currentRate;
            rTransferAmount -= rBurn;
        }
    }

    function getRate() external view returns (uint256) {
        return _getRate();
    }

    /// calculate current reflect rate
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    /// calculate current token supply
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        uint256 i;
        for (i; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply -= _rOwned[_excluded[i]];
            tSupply -= _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    /// internal burn function
    function _burn(
        address account,
        uint256 tAmount,
        uint256 rAmount
    ) private {
        require(
            _rOwned[account] >= rAmount,
            "ERC20: burn amount exceeds balance"
        );
        _rOwned[account] -= rAmount;
        if (isExcluded[account]) {
            require(
                _tOwned[account] >= tAmount,
                "ERC20: burn amount exceeds balance"
            );

            _tOwned[account] -= tAmount;
        }
        _reflectBurn(rAmount, tAmount, account);
    }

    //
    // Rick mode
    //

    /**
        Add address that will not pay transfer fees
        @param user address to mark as fee-free
     */
    function addFeeFree(address user) external onlyOwner {
        isFeeFree[user] = true;
    }

    /**
        Remove address form privileged list
        @param user user to remove
     */
    function removeFeeFree(address user) external onlyOwner {
        isFeeFree[user] = false;
    }

    /**
        Exclude address form earing transfer fees
        @param account address to exclude from earning
     */
    function excludeAccount(address account) external onlyOwner {
        require(!isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        isExcluded[account] = true;
        _excluded.push(account);
    }

    /**
        Include address back to earn transfer fees
        @param account address to include
     */
    function includeAccount(address account) external onlyOwner {
        require(isExcluded[account], "Account is already included");
        uint256 i;
        for (i; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    /**
        Take ETH accidentally send to contract
    */
    function withdrawEth() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /**
        Take any ERC20 sent to contract
        @param token token address
    */
    function withdrawErc20(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        // use broken IERC20
        INterfacesNoR(token).transfer(owner, balance);
    }
}

//by Patrick