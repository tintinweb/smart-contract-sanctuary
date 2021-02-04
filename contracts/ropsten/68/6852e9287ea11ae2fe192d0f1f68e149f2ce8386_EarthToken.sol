/* 
      ,c::;;;:;.                   ;l'                  .::;:::::,.              ';;;:cc;;:,.            .,.        ,.                                             
     .dl.......                   :dod'                 ;x;....'':o;             ....;xl....             'd,       .d;                                             
     .o:                         'd, lo.                ;d.       ,d.                .o;                 'd,       .d;                                             
     .dl......                  .oc  .dc                ;d.      .cl.                .o;                 'd;       'd;                                             
     .dd;;;;;;.                 lo.   'd,               ;kl;:cc::c;.                 .o;                 'xo,;;;;;,ck;                                             
     .o:                       :d.     :d.              ;x;..:xkc                    .o;                 'd,       .d;                                             
     .o:                      'd;       lo.             ;d.   'col.                  .o;                 'd,       .d;                                             
     .do'''''''.             .oc        .o:             ;d.     .cd,                 .o;                 'd,       .d;                                             
      ';;;;;;;,.              .          ..             ..        ..                  ..                 ...        ..         
      
*/
// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "./context.sol";
import "./IERC20.sol";
import "./safemath.sol";
import "./address.sol";
import "./ownable.sol";

contract EarthToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private constant NAME = "Earth Token";
    string private constant SYMBOL = "EARTH";
    uint8 private constant DECIMALS = 18;

    mapping(address => uint256) private rewards;
    mapping(address => uint256) private actual;
    mapping(address => mapping(address => uint256)) private allowances;

    mapping(address => bool) private excludedFromFees;
    mapping(address => bool) private excludedFromRewards;
    address[] private rewardExcluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant ACTUAL_TOTAL = 100_000_000 * 1e18;
    uint256 private rewardsTotal = (MAX - (MAX % ACTUAL_TOTAL));
    uint256 private holderFeeTotal;
    uint256 private marketingFeeTotal;
    uint256 private lpFeeTotal;
    uint256 private merchantFeeTotal;

    uint256 public taxPercentage = 3;
    uint256 public holderTaxAlloc = 10;
    uint256 public marketingTaxAlloc = 10;
    uint256 public lpTaxAlloc = 10;
    uint256 public merchantTaxAlloc;
    uint256 public totalTaxAlloc = marketingTaxAlloc.add(holderTaxAlloc).add(lpTaxAlloc).add(merchantTaxAlloc);

    address public marketingAddress;
    address public lpStakingAddress;
    address public merchantStakingAddress;

    constructor(address _marketingAddress) {
        rewards[_marketingAddress] = rewardsTotal;
        emit Transfer(address(0), _marketingAddress, ACTUAL_TOTAL);

        marketingAddress = _marketingAddress;

        excludeFromRewards(_msgSender());
        excludeFromFees(_marketingAddress);

        if (_marketingAddress != _msgSender()) {
            excludeFromRewards(_marketingAddress);
            excludeFromFees(_msgSender());
        }

        excludeFromFees(address(0x000000000000000000000000000000000000dEaD));
    }

    function name() external pure returns (string memory) {
        return NAME;
    }

    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() external pure override returns (uint256) {
        return ACTUAL_TOTAL;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        if (excludedFromRewards[_account]) {
            return actual[_account];
        }
        return tokenWithRewards(rewards[_account]);
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        _transfer(_sender, _recipient, _amount);

        _approve(
        _sender,
            _msgSender(),
            allowances[_sender][_msgSender()].sub(_amount, "ERC20: transfer amount exceeds allowance")
        );

        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
        _approve(_msgSender(), _spender, allowances[_msgSender()][_spender].add(_addedValue));
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            _spender,
            allowances[_msgSender()][_spender].sub(_subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    function isExcludedFromRewards(address _account) external view returns (bool) {
        return excludedFromRewards[_account];
    }

    function isExcludedFromFees(address _account) external view returns (bool) {
        return excludedFromFees[_account];
    }

    function totalFees() external view returns (uint256) {
        return holderFeeTotal.add(marketingFeeTotal).add(lpFeeTotal).add(merchantFeeTotal);
    }

    function totalHolderFees() external view returns (uint256) {
        return holderFeeTotal;
    }

    function totalMarketingFees() external view returns (uint256) {
        return marketingFeeTotal;
    }

    function totalLpFees() external view returns (uint256) {
        return lpFeeTotal;
    }

    function totalMerchantFees() external view returns (uint256) {
        return merchantFeeTotal;
    }

    function distribute(uint256 _actualAmount) public {
        address sender = _msgSender();
        require(!excludedFromRewards[sender], "Excluded addresses cannot call this function");

        (uint256 rewardAmount, , , , ) = _getValues(_actualAmount);
        rewards[sender] = rewards[sender].sub(rewardAmount);
        rewardsTotal = rewardsTotal.sub(rewardAmount);
        holderFeeTotal = holderFeeTotal.add(_actualAmount);
    }

    function excludeFromFees(address _account) public onlyOwner() {
        require(!excludedFromFees[_account], "Account is already excluded from fee");
        excludedFromFees[_account] = true;
    }

    function includeInFees(address _account) public onlyOwner() {
        require(excludedFromFees[_account], "Account is already included in fee");
        excludedFromFees[_account] = false;
    }

    function excludeFromRewards(address _account) public onlyOwner() {
        require(!excludedFromRewards[_account], "Account is already excluded from reward");

        if (rewards[_account] > 0) {
            actual[_account] = tokenWithRewards(rewards[_account]);
        }

        excludedFromRewards[_account] = true;
        rewardExcluded.push(_account);
    }

    function includeInRewards(address _account) public onlyOwner() {
        require(excludedFromRewards[_account], "Account is already included in rewards");

        for (uint256 i = 0; i < rewardExcluded.length; i++) {
            if (rewardExcluded[i] == _account) {
                rewardExcluded[i] = rewardExcluded[rewardExcluded.length - 1];
                actual[_account] = 0;
                excludedFromRewards[_account] = false;
                rewardExcluded.pop();
                break;
            }
        }
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");

        uint256 currentTaxPercentage = taxPercentage;
        if (excludedFromFees[_sender] || excludedFromFees[_recipient]) {
            taxPercentage = 0;
        } else {
            uint256 fee = _getFee(_amount);
            uint256 marketingFee = _getMarketingFee(fee);
            uint256 lpFee = _getLpFee(fee);
            uint256 merchantFee = _getMerchantFee(fee);

            _updateMarketingFee(marketingFee);
            _updateLpFee(lpFee);
            _updateMerchantFee(merchantFee);
        }

        if (excludedFromRewards[_sender] && !excludedFromRewards[_recipient]) {
            _transferWithoutSenderRewards(_sender, _recipient, _amount);
        } else if (!excludedFromRewards[_sender] && excludedFromRewards[_recipient]) {
            _transferWithRecipientRewards(_sender, _recipient, _amount);
        } else if (!excludedFromRewards[_sender] && !excludedFromRewards[_recipient]) {
            _transferWithRewards(_sender, _recipient, _amount);
        } else if (excludedFromRewards[_sender] && excludedFromRewards[_recipient]) {
            _transferWithoutRewards(_sender, _recipient, _amount);
        } else {
            _transferWithRewards(_sender, _recipient, _amount);
        }

        if (currentTaxPercentage != taxPercentage) {
            taxPercentage = currentTaxPercentage;
        }
    }

    function _transferWithRewards(
        address _sender,
        address _recipient,
        uint256 _actualAmount
    ) private {
        (
            uint256 rewardAmount,
            uint256 rewardTransferAmount,
            uint256 rewardFee,
            uint256 actualTransferAmount,
            uint256 actualFee
        ) = _getValues(_actualAmount);

        rewards[_sender] = rewards[_sender].sub(rewardAmount);
        rewards[_recipient] = rewards[_recipient].add(rewardTransferAmount);
        _updateHolderFee(rewardFee, actualFee);
        emit Transfer(_sender, _recipient, actualTransferAmount);
    }

    function _transferWithRecipientRewards(
        address _sender,
        address _recipient,
        uint256 _actualAmount
    ) private {
        (
            uint256 rewardAmount,
            uint256 rewardTransferAmount,
            uint256 rewardFee,
            uint256 actualTransferAmount,
            uint256 actualFee
        ) = _getValues(_actualAmount);

        rewards[_sender] = rewards[_sender].sub(rewardAmount);
        actual[_recipient] = actual[_recipient].add(actualTransferAmount);
        rewards[_recipient] = rewards[_recipient].add(rewardTransferAmount);
        _updateHolderFee(rewardFee, actualFee);
        emit Transfer(_sender, _recipient, actualTransferAmount);
    }

    function _transferWithoutSenderRewards(
        address _sender,
        address _recipient,
        uint256 _actualAmount
    ) private {
        (
            uint256 rewardAmount,
            uint256 rewardTransferAmount,
            uint256 rewardFee,
            uint256 actualTransferAmount,
            uint256 actualFee
        ) = _getValues(_actualAmount);

        actual[_sender] = actual[_sender].sub(_actualAmount);
        rewards[_sender] = rewards[_sender].sub(rewardAmount);
        rewards[_recipient] = rewards[_recipient].add(rewardTransferAmount);
        _updateHolderFee(rewardFee, actualFee);
        emit Transfer(_sender, _recipient, actualTransferAmount);
    }

    function _transferWithoutRewards(
        address _sender,
        address _recipient,
        uint256 _actualAmount
    ) private {
        (
            uint256 rewardAmount,
            uint256 rewardTransferAmount,
            uint256 rewardFee,
            uint256 actualTransferAmount,
            uint256 actualFee
        ) = _getValues(_actualAmount);

        actual[_sender] = actual[_sender].sub(_actualAmount);
        rewards[_sender] = rewards[_sender].sub(rewardAmount);
        actual[_recipient] = actual[_recipient].add(actualTransferAmount);
        rewards[_recipient] = rewards[_recipient].add(rewardTransferAmount);
        _updateHolderFee(rewardFee, actualFee);
        emit Transfer(_sender, _recipient, actualTransferAmount);
    }

    function _updateHolderFee(uint256 _rewardFee, uint256 _actualFee) private {
        rewardsTotal = rewardsTotal.sub(_rewardFee);
        holderFeeTotal = holderFeeTotal.add(_actualFee);
    }

    function _updateMarketingFee(uint256 _marketingFee) private {
        if (marketingAddress == address(0)) {
            return;
        }

        uint256 rewardsRate = _getRewardsRate();
        uint256 rewardMarketingFee = _marketingFee.mul(rewardsRate);
        marketingFeeTotal = marketingFeeTotal.add(_marketingFee);

        rewards[marketingAddress] = rewards[marketingAddress].add(rewardMarketingFee);
        if (excludedFromRewards[marketingAddress]) {
            actual[marketingAddress] = actual[marketingAddress].add(_marketingFee);
        }
    }

    function _updateLpFee(uint256 _lpFee) private {
        if (lpStakingAddress == address(0)) {
            return;
        }

        uint256 rewardsRate = _getRewardsRate();
        uint256 rewardLpFee = _lpFee.mul(rewardsRate);
        lpFeeTotal = lpFeeTotal.add(_lpFee);

        rewards[lpStakingAddress] = rewards[lpStakingAddress].add(rewardLpFee);
        if (excludedFromRewards[lpStakingAddress]) {
            actual[lpStakingAddress] = actual[lpStakingAddress].add(_lpFee);
        }
    }

    function _updateMerchantFee(uint256 _merchantFee) private {
        if (merchantStakingAddress == address(0)) {
            return;
        }

        uint256 rewardsRate = _getRewardsRate();
        uint256 rewardMerchantFee = _merchantFee.mul(rewardsRate);
        merchantFeeTotal = merchantFeeTotal.add(_merchantFee);

        rewards[merchantStakingAddress] = rewards[merchantStakingAddress].add(rewardMerchantFee);
        if (excludedFromRewards[merchantStakingAddress]) {
            actual[merchantStakingAddress] = actual[merchantStakingAddress].add(_merchantFee);
        }
    }

    function rewardsFromToken(uint256 _actualAmount, bool _deductTransferFee) public view returns (uint256) {
        require(_actualAmount <= ACTUAL_TOTAL, "Amount must be less than supply");
        if (!_deductTransferFee) {
            (uint256 rewardAmount, , , , ) = _getValues(_actualAmount);
            return rewardAmount;
        } else {
            (, uint256 rewardTransferAmount, , , ) = _getValues(_actualAmount);
            return rewardTransferAmount;
        }
    }

    function tokenWithRewards(uint256 _rewardAmount) public view returns (uint256) {
        require(_rewardAmount <= rewardsTotal, "Amount must be less than total rewards");
        uint256 rewardsRate = _getRewardsRate();
        return _rewardAmount.div(rewardsRate);
    }

    function _getValues(uint256 _actualAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 actualTransferAmount, uint256 actualFee) = _getActualValues(_actualAmount);
        uint256 rewardsRate = _getRewardsRate();
        (
            uint256 rewardAmount,
            uint256 rewardTransferAmount,
            uint256 rewardFee
        ) = _getRewardValues(_actualAmount, actualFee, rewardsRate);

        return (rewardAmount, rewardTransferAmount, rewardFee, actualTransferAmount, actualFee);
    }

    function _getActualValues(uint256 _actualAmount) private view returns (uint256, uint256) {
        uint256 actualFee = _getFee(_actualAmount);
        uint256 actualHolderFee = _getHolderFee(actualFee);
        uint256 actualTransferAmount = _actualAmount.sub(actualFee);
        return (actualTransferAmount, actualHolderFee);
    }

    function _getRewardValues(
        uint256 _actualAmount,
        uint256 _actualHolderFee,
        uint256 _rewardsRate
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 actualFee = _getFee(_actualAmount).mul(_rewardsRate);
        uint256 rewardAmount = _actualAmount.mul(_rewardsRate);
        uint256 rewardTransferAmount = rewardAmount.sub(actualFee);
        uint256 rewardFee = _actualHolderFee.mul(_rewardsRate);
        return (rewardAmount, rewardTransferAmount, rewardFee);
    }

    function _getRewardsRate() private view returns (uint256) {
        (uint256 rewardsSupply, uint256 actualSupply) = _getCurrentSupply();
        return rewardsSupply.div(actualSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rewardsSupply = rewardsTotal;
        uint256 actualSupply = ACTUAL_TOTAL;

        for (uint256 i = 0; i < rewardExcluded.length; i++) {
            if (rewards[rewardExcluded[i]] > rewardsSupply || actual[rewardExcluded[i]] > actualSupply) {
                return (rewardsTotal, ACTUAL_TOTAL);
            }

            rewardsSupply = rewardsSupply.sub(rewards[rewardExcluded[i]]);
            actualSupply = actualSupply.sub(actual[rewardExcluded[i]]);
        }

        if (rewardsSupply < rewardsTotal.div(ACTUAL_TOTAL)) {
            return (rewardsTotal, ACTUAL_TOTAL);
        }

        return (rewardsSupply, actualSupply);
    }

    function _getFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(taxPercentage).div(100);
    }

    function _getHolderFee(uint256 _tax) private view returns (uint256) {
        return _tax.mul(holderTaxAlloc).div(totalTaxAlloc);
    }

    function _getMarketingFee(uint256 _tax) private view returns (uint256) {
        return _tax.mul(marketingTaxAlloc).div(totalTaxAlloc);
    }

    function _getLpFee(uint256 _tax) private view returns (uint256) {
        return _tax.mul(lpTaxAlloc).div(totalTaxAlloc);
    }

    function _getMerchantFee(uint256 _tax) private view returns (uint256) {
        return _tax.mul(merchantTaxAlloc).div(totalTaxAlloc);
    }

    function setTaxPercentage(uint256 _taxPercentage) external onlyOwner {
        require(_taxPercentage >= 1 && _taxPercentage <= 10, "Value is outside of range 1-10");
        taxPercentage = _taxPercentage;
    }

    function setTaxAllocations(
        uint256 _holderTaxAlloc,
        uint256 _marketingTaxAlloc,
        uint256 _lpTaxAlloc,
        uint256 _merchantTaxAlloc
    ) external onlyOwner {
        totalTaxAlloc = _holderTaxAlloc.add(_marketingTaxAlloc).add(_lpTaxAlloc).add(_merchantTaxAlloc);

        require(_holderTaxAlloc >= 5 && _holderTaxAlloc <= 10, "_holderTaxAlloc is outside of range 5-10");
        require(_lpTaxAlloc >= 5 && _lpTaxAlloc <= 10, "_lpTaxAlloc is outside of range 5-10");
        require(_marketingTaxAlloc <= 10, "_marketingTaxAlloc is greater than 10");
        require(_merchantTaxAlloc <= 10, "_merchantTaxAlloc is greater than 10");

        holderTaxAlloc = _holderTaxAlloc;
        marketingTaxAlloc = _marketingTaxAlloc;
        lpTaxAlloc = _lpTaxAlloc;
        merchantTaxAlloc = _merchantTaxAlloc;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = _marketingAddress;
    }

    function setLpStakingAddress(address _lpStakingAddress) external onlyOwner {
        lpStakingAddress = _lpStakingAddress;
    }

    function setMerchantStakingAddress(address _merchantStakingAddress) external onlyOwner {
        merchantStakingAddress = _merchantStakingAddress;
    }
}