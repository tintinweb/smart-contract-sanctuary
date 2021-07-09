// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";

interface ISwapAndLiquify{
    function inSwapAndLiquify() external returns(bool);
    function swapAndLiquify(uint256 tokenAmount) external;
    function uniswapV2Router() external returns(address);
}

contract ALDN is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxTxAmount;

    address[] private _excluded;

    uint256 private constant MAX = type(uint256).max;
    uint256 private _tTotal = 1000000000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Magiclamp Governance Token";
    string private _symbol = "ALDN";
    uint8 private _decimals = 9;

    // fee factors
    uint256 public taxFee = 5;
    uint256 private _previousTaxFee;

    uint256 public liquidityFee = 5;
    uint256 private _previousLiquidityFee;

    bool public swapAndLiquifyEnabled = true;

    uint256 public maxTxAmount = 5000000 * 10**6 * 10**9;
    uint256 private _numTokensSellToAddToLiquidity = 500000 * 10**6 * 10**9;

	ISwapAndLiquify public swapAndLiquify;

    // @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    // @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    // @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    // @notice A checkpoint for marking number of votes from a given block
    struct VotesCheckpoint {
        uint32 fromBlock;
        uint96 tOwned;
        uint256 rOwned;
    }

    // @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => VotesCheckpoint)) public votesCheckpoints;

    // @notice The number of votes checkpoints for each account
    mapping (address => uint32) public numVotesCheckpoints;

    // @notice A checkpoint for marking rate from a given block
    struct RateCheckpoint {
        uint32 fromBlock;
        uint256 rate;
    }

    // @notice A record of rates, by index
    mapping (uint32 => RateCheckpoint) public rateCheckpoints;

    // @notice The number of rate checkpoints
    uint32 public numRateCheckpoints;

    // @notice An event thats emitted when swap and liquidify address is changed
    event SwapAndLiquifyAddressChanged(address priviousAddress, address newAddress);

    // @notice An event thats emitted when swap and liquidify enable is changed
    event SwapAndLiquifyEnabledChanged(bool enabled);

    // @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    // @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousROwned, uint previousTOwned, uint newROwned, uint newTOwned);

    // @notice An event thats emitted when reflection rate changes
    event RateChanged(uint previousRate, uint newRate);

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        
        // excludes
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromMaxTxAmount[owner()] = true;
        _isExcluded[address(this)] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromMaxTxAmount[address(this)] = true;
        _isExcluded[0x000000000000000000000000000000000000dEaD] = true;

        emit Transfer(address(0), owner(), _tTotal);
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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 spenderAllowance = _allowances[sender][_msgSender()];
        if (sender != _msgSender() && spenderAllowance != type(uint256).max) {
            _approve(sender, _msgSender(), spenderAllowance.sub(amount,"ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue,"ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function _getOwns(address account) private view returns (uint256, uint256) {
        uint256 rOwned = _isExcluded[account] ? 0 : _rOwned[account];
        uint256 tOwned = _isExcluded[account] ? _tOwned[account] : 0;

        return (rOwned, tOwned);
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "ALDN::deliver: excluded addresses cannot call this function");

        (uint256 oldROwned, uint256 oldTOwned) = _getOwns(sender);

        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);

        (uint256 newROwned, uint256 newTOwned) = _getOwns(sender);

        _moveDelegates(delegates[sender], delegates[sender], oldROwned, oldTOwned, newROwned, newTOwned);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "ALDN::reflectionFromToken: amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function _tokenFromReflection(uint256 rAmount, uint256 rate) private pure returns (uint256) {
        return rAmount.div(rate);
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "ALDN::tokenFromReflection: amount must be less than total reflections");
        
        return _tokenFromReflection(rAmount, _getCurrentRate());
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "ALDN::excludeFromReward: account is already excluded");
        
        (uint256 oldROwned, uint256 oldTOwned) = _getOwns(account);

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);

        (uint256 newROwned, uint256 newTOwned) = _getOwns(account);

        _moveDelegates(delegates[account], delegates[account], oldROwned, oldTOwned, newROwned, newTOwned);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "ALDN::includeInReward: account is already included");
        
        (uint256 oldROwned, uint256 oldTOwned) = _getOwns(account);

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
        
        (uint256 newROwned, uint256 newTOwned) = _getOwns(account);

        _moveDelegates(delegates[account], delegates[account], oldROwned, oldTOwned, newROwned, newTOwned);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
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

    function setTaxFeePercent(uint256 newFee) external onlyOwner {
        taxFee = newFee;
    }

    function setLiquidityFeePercent(uint256 newFee) external onlyOwner {
        liquidityFee = newFee;
    }

    function setMaxTxPercent(uint256 newPercent) external onlyOwner {
        maxTxAmount = _tTotal.mul(newPercent).div(10**2);
    }

	function setSwapAndLiquifyAddress(address newAddress) public onlyOwner {
        address priviousAddress = address(swapAndLiquify);        
        require(priviousAddress != newAddress, "ALDN::setSwapAndLiquifyAddress: same address");
        
        _approve(address(this), address(newAddress), type(uint256).max);
        swapAndLiquify = ISwapAndLiquify(newAddress);

        emit SwapAndLiquifyAddressChanged(priviousAddress, newAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;

        emit SwapAndLiquifyEnabledChanged(_enabled);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getCurrentRate());

        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);

        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        
        return (rAmount, rTransferAmount, rFee);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        
        return (rSupply, tSupply);
    }

    /**
     * @notice Gets the current rate
     * @return The current rate
     */
    function _getCurrentRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        
        return rSupply.div(tSupply);
    }

    /**
     * @notice Gets the rate at a block number
     * @param blockNumber The block number to get the rate at
     * @return The rate at the given block
     */
    function _getPriorRate(uint blockNumber) private view returns (uint256) {
        if (numRateCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (rateCheckpoints[numRateCheckpoints - 1].fromBlock <= blockNumber) {
            return rateCheckpoints[numRateCheckpoints - 1].rate;
        }

        // Next check implicit zero balance
        if (rateCheckpoints[0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = numRateCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            RateCheckpoint memory rcp = rateCheckpoints[center];
            if (rcp.fromBlock == blockNumber) {
                return rcp.rate;
            } else if (rcp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return rateCheckpoints[lower].rate;
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getCurrentRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(taxFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(liquidityFee).div(10**2);
    }

    function removeAllFee() private {
        if (taxFee == 0 && liquidityFee == 0) return;

        _previousTaxFee = taxFee;
        _previousLiquidityFee = liquidityFee;

        taxFee = 0;
        liquidityFee = 0;
    }

    function restoreAllFee() private {
        taxFee = _previousTaxFee;
        liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromMaxTxAmount(address account) public view returns (bool) {
        return _isExcludedFromMaxTxAmount[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ALDN::_approve: approve from the zero address");
        require(spender != address(0), "ALDN::_approve: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ALDN::_transfer: transfer from the zero address");
        require(to != address(0), "ALDN::_transfer: transfer to the zero address");
        require(amount > 0, "ALDN::_transfer: amount must be greater than zero");
        require(_isExcludedFromMaxTxAmount[from] || _isExcludedFromMaxTxAmount[to] || amount <= maxTxAmount, "ALDN::_transfer: transfer amount exceeds the maxTxAmount.");
        
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
        if (overMinTokenBalance && from != owner() && from != swapAndLiquify.uniswapV2Router() && from != address(swapAndLiquify) 
        && !swapAndLiquify.inSwapAndLiquify() && swapAndLiquifyEnabled) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            // add liquidity
            swapAndLiquify.swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (sender == recipient) {
            emit Transfer(sender, recipient, amount);
            return;
        }

        (uint256 oldSenderROwned, uint256 oldSenderTOwned) = _getOwns(sender);
        (uint256 oldRecipientROwned, uint256 oldRecipientTOwned) = _getOwns(recipient);
        {
            if (!takeFee) {
                removeAllFee();
            }

            bool isExcludedSender = _isExcluded[sender];
            bool isExcludedRecipient = _isExcluded[recipient];
            if (isExcludedSender && !isExcludedRecipient) {
                _transferFromExcluded(sender, recipient, amount);
            } else if (!isExcludedSender && isExcludedRecipient) {
                _transferToExcluded(sender, recipient, amount);
            } else if (!isExcludedSender && !isExcludedRecipient) {
                _transferStandard(sender, recipient, amount);
            } else if (isExcludedSender && isExcludedRecipient) {
                _transferBothExcluded(sender, recipient, amount);
            } else {
                _transferStandard(sender, recipient, amount);
            }

            if (!takeFee) {
                restoreAllFee();
            }
        }
        (uint256 newSenderROwned, uint256 newSenderTOwned) = _getOwns(sender);
        (uint256 newRecipientROwned, uint256 newRecipientTOwned) = _getOwns(recipient);

        _moveDelegates(delegates[sender], delegates[recipient], oldSenderROwned.sub(newSenderROwned), oldSenderTOwned.sub(newSenderTOwned), newRecipientROwned.sub(oldRecipientROwned), newRecipientTOwned.sub(oldRecipientTOwned));
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
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

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
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

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
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
    
    function burn(uint256 burnQuantity) external override pure returns (bool) {
        burnQuantity;
        return false;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(_msgSender(), delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(_name)), _getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "ALDN::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "ALDN::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "ALDN::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the votes balance of `checkpoint` with `rate`
     * @param rOwned The reflection value to get votes balance
     * @param tOwned The balance value to get votes balance
     * @param rate The rate to get votes balance
     * @return The number of votes with params
     */
    function _getVotes(uint256 rOwned, uint256 tOwned, uint256 rate) private pure returns (uint96) {
        uint256 votes = 0;
        votes = votes.add(_tokenFromReflection(rOwned, rate));
        votes = votes.add(tOwned);
        return uint96(votes);
    }

    /**
     * @notice Gets the votes balance of `checkpoint` with `rate`
     * @param checkpoint The checkpoint to get votes balance
     * @param rate The rate to get votes balance
     * @return The number of votes of `checkpoint` with `rate`
     */
    function _getVotes(VotesCheckpoint memory checkpoint, uint256 rate) private pure returns (uint96) {
        return _getVotes(checkpoint.rOwned, checkpoint.tOwned, rate);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numVotesCheckpoints[account];
        return nCheckpoints > 0 ? _getVotes(votesCheckpoints[account][nCheckpoints - 1], _getCurrentRate()) : 0;
    }

     /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "ALDN::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numVotesCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        uint256 rate = _getPriorRate(blockNumber);

        // First check most recent balance
        if (votesCheckpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return _getVotes(votesCheckpoints[account][nCheckpoints - 1], rate);
        }

        // Next check implicit zero balance
        if (votesCheckpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            if (votesCheckpoints[account][center].fromBlock == blockNumber) {
                return _getVotes(votesCheckpoints[account][center], rate);
            } else if (votesCheckpoints[account][center].fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return _getVotes(votesCheckpoints[account][lower], rate);
    }

    function _delegate(address delegator, address delegatee) private {
        address currentDelegate = delegates[delegator];
        (uint256 delegatorROwned, uint256 delegatorTOwned) = _getOwns(delegator);
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorROwned, delegatorTOwned, delegatorROwned, delegatorTOwned);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 subROwned, uint256 subTOwned, uint256 addROwned, uint256 addTOwned) private {
        if (srcRep != dstRep) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numVotesCheckpoints[srcRep];
                uint256 srcRepOldR = srcRepNum > 0 ? votesCheckpoints[srcRep][srcRepNum - 1].rOwned : 0;
                uint256 srcRepOldT = srcRepNum > 0 ? votesCheckpoints[srcRep][srcRepNum - 1].tOwned : 0;
                uint256 srcRepNewR = srcRepOldR.sub(subROwned);
                uint256 srcRepNewT = srcRepOldT.sub(subTOwned);
                if (srcRepOldR != srcRepNewR || srcRepOldT != srcRepNewT) {
                    _writeCheckpoint(srcRep, srcRepNum, srcRepOldR, srcRepOldT, srcRepNewR, srcRepNewT);
                }
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numVotesCheckpoints[dstRep];
                uint256 dstRepOldR = dstRepNum > 0 ? votesCheckpoints[dstRep][dstRepNum - 1].rOwned : 0;
                uint256 dstRepOldT = dstRepNum > 0 ? votesCheckpoints[dstRep][dstRepNum - 1].tOwned : 0;
                uint256 dstRepNewR = dstRepOldR.add(addROwned);
                uint256 dstRepNewT = dstRepOldT.add(addTOwned);
                if (dstRepOldR != dstRepNewR || dstRepOldT != dstRepNewT) {
                    _writeCheckpoint(dstRep, dstRepNum, dstRepOldR, dstRepOldT, dstRepNewR, dstRepNewT);
                }
            }
        } else if (dstRep != address(0)) {
            uint32 dstRepNum = numVotesCheckpoints[dstRep];
            uint256 dstRepOldR = dstRepNum > 0 ? votesCheckpoints[dstRep][dstRepNum - 1].rOwned : 0;
            uint256 dstRepOldT = dstRepNum > 0 ? votesCheckpoints[dstRep][dstRepNum - 1].tOwned : 0;
            uint256 dstRepNewR = dstRepOldR.add(addROwned).sub(subROwned);
            uint256 dstRepNewT = dstRepOldT.add(addTOwned).sub(subTOwned);
            if (dstRepOldR != dstRepNewR || dstRepOldT != dstRepNewT) {
                _writeCheckpoint(dstRep, dstRepNum, dstRepOldR, dstRepOldT, dstRepNewR, dstRepNewT);
            }
        }

        uint256 rate = _getCurrentRate();
        uint256 rateOld = numRateCheckpoints > 0 ? rateCheckpoints[numRateCheckpoints - 1].rate : 0;
        if (rate != rateOld) {
            _writeRateCheckpoint(numRateCheckpoints, rateOld, rate);
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldROwned, uint256 oldTOwned, uint256 newROwned, uint256 newTOwned) private {
        uint32 blockNumber = safe32(block.number, "ALDN::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && votesCheckpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            votesCheckpoints[delegatee][nCheckpoints - 1].tOwned = uint96(newTOwned);
            votesCheckpoints[delegatee][nCheckpoints - 1].rOwned = newROwned;
        } else {
            votesCheckpoints[delegatee][nCheckpoints] = VotesCheckpoint(blockNumber, uint96(newTOwned), newROwned);
            numVotesCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldROwned, oldTOwned, newROwned, newTOwned);
    }

    function _writeRateCheckpoint(uint32 nCheckpoints, uint256 oldRate, uint256 newRate) private {
        uint32 blockNumber = safe32(block.number, "ALDN::_writeRateCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && rateCheckpoints[nCheckpoints - 1].fromBlock == blockNumber) {
            rateCheckpoints[nCheckpoints - 1].rate = newRate;
        } else {
            rateCheckpoints[nCheckpoints].fromBlock = blockNumber;
            rateCheckpoints[nCheckpoints].rate = newRate;
            numRateCheckpoints = nCheckpoints + 1;
        }

        emit RateChanged(oldRate, newRate);
    }

    function safe32(uint n, string memory errorMessage) private pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function _getChainId() private view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
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
     * @dev custom add
     */
    function burn(uint256 burnQuantity) external returns (bool);

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

import "./Context.sol";

// File: @openzeppelin/contracts/access/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    address private _authorizedNewOwner;

    event OwnershipTransferAuthorization(address indexed authorizedAddress);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns the address of the current authorized new owner.
     */
    function authorizedNewOwner() public view virtual returns (address) {
        return _authorizedNewOwner;
    }

    /**
     * @notice Authorizes the transfer of ownership from _owner to the provided address.
     * NOTE: No transfer will occur unless authorizedAddress calls assumeOwnership( ).
     * This authorization may be removed by another call to this function authorizing
     * the null address.
     *
     * @param authorizedAddress The address authorized to become the new owner.
     */
    function authorizeOwnershipTransfer(address authorizedAddress) external onlyOwner {
        _authorizedNewOwner = authorizedAddress;
        emit OwnershipTransferAuthorization(_authorizedNewOwner);
    }

    /**
     * @notice Transfers ownership of this contract to the _authorizedNewOwner.
     */
    function assumeOwnership() external {
        require(_msgSender() == _authorizedNewOwner, "Ownable: only the authorized new owner can accept ownership");
        emit OwnershipTransferred(_owner, _authorizedNewOwner);
        _owner = _authorizedNewOwner;
        _authorizedNewOwner = address(0);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * @param confirmAddress The address wants to give up ownership.
     */
    function renounceOwnership(address confirmAddress) public virtual onlyOwner {
        require(confirmAddress == _owner, "Ownable: confirm address is wrong");
        emit OwnershipTransferred(_owner, address(0));
        _authorizedNewOwner = address(0);
        _owner = address(0);
    }
    
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