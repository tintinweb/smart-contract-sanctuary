/*////////////////////////////////////////////////////////////////////////////////////////////////////////////
     
                                                                ╓╥[email protected]▓▒▒╓
                 $$\ $$\             $$\                     ╓g╬╜░g╣Ñ▒▒░▒▒@
                 $$ |\__|            $$ |                   ╣▒▒▄Ñ╜`    ╙▒▒▒▒▒╕
            $$$$$$$ |$$\  $$$$$$\  $$$$$$\   $$\   $$\     ▐▓▒╙░   ╓Ç,  ╙▒╓▒╫N,
            $$  __$$ |$$ |$$  __$$\ \_$$  _|  $$ |  $$ | ,╥▓▒╖▓@g▄ '╙▀   ░░▒``,╥
            $$ /  $$ |$$ |$$ |  \__|  $$ |    $$ |  $$ | ▓╣▓▓▓▓▓▓`) . =.  ▐▓@]▒
            $$ |  $$ |$$ |$$ |        $$ |$$\ $$ |  $$ | ╙▓▓▓▓@╠▓╖▒▓²,╜  ` ╢▒╣╛
            \$$$$$$$ |$$ |$$ |        \$$$$  |\$$$$$$$ |  "▓▓╢▓╫▓▓▓▒░,╓`  ▒▒H╓
             \_______|\__|\__|         \____/  \____$$ |    ╙▓▒╨╫▀▀▀▒,r║▒░,  ░╖
                                              $$\   $$ |      ▒ ,▒╓p▒░░░░░░░░░░▒
                                              \$$$$$$  |    ,m░░░░░░░   ░░░░░░░▒▓
                                               \______/   g╣░░ (,,,,    ░░  ░░░▒▒
                                           ╓∩∩╥∩∩∩╓       ▓╖,▓█▓▓▓H░░░▒╖  [   ░░▒▌
                                         ╓` ╓░      ▒╓    ▓▓▓▓▓▓▓▓@▒▒╠▄░▓,░   ░▒▒
                                        Æ  ╓░         ▒╓   `▀▓▓▓▓▓▓▓▓▓▓▓▓▓    ░▒▓
                                       ╣  ╒       ,     ▒┐   ▓▓▓▓▓▓▀░░░░▓╣   ░▒╢
                                      ▒   ▒       ▒       ▒  ▓▓▓▓▓@╦~░▒▒▒║   ░▒
                                    ,▒   ▒░      ░▒▌        \▐▓▓▓╢▒▒▒▒░░▒║░  ░╢
                                    ▒   ╣       ,▒▓▓          ▓▓▓╣╢▒▒▒▒▒▒▌▒  ▒╢
                                   ╣░  ╢       ╓╢▓▓╣░          ╙╣▒▒▒▒▒▒▒▒▓░  ░║
                                  ╣░  ╢░     ,▒╫▓▓▓╣▒░           ▓▒╖░░░▒╢▓╢  ░▒
                                 ║░  ╔▒    ,╓╩  ▓╢▓▓╣▒░           ╙▓Ñ▒@╢╢▌╘▒  ▒
                                ╔░  ╓░    ╓╝    ╘╣╣╢▓╣▒░            ╣╖╙▓╣▓ ▒  ]
                               ╣░  ║░   ,╜       ╙╣╣▓▓╣╣▒░           ▓▒╟╢▓ ║░░▒
                             ,▒──,╜░   ╓`         ╙╣╣╣▓╣╣▒░          ╢▒▒╢▓  ▒░▒
                            ╓░  ╓▒%─ `╨            ╙▓╣╬▓╣╣▒░░        ▓╢╫▓`  ▒░▒
                           ╗   ╢░▒  ╓▓               ▀╣▓▓█╣▒░░      ▐▓▓▓╜   ▒▓▓▓
                          ╢░  ╣▒   ░╜` ┐ $$$$$$\  $$\  ▀███╣▒▒░░░  á▓▓▀     ▓▒▒▒'░░░▒▒▒∩,
                         /╜'░╟▒░    ░ ╓,$$  __$$\ \__|        ╚╩╩╩╩▀▀              ""    ``
                        ╔²  )╜`'`*╚▀    $$ /  \__|$$\ $$$$$$$\   $$$$$$\  $$$$$$$\   $$$$$$$\  $$$$$$\ 
                      ╢▒▒═,N    ▒▓ 4╫   $$$$\     $$ |$$  __$$\  \____$$\ $$  __$$\ $$  _____|$$  __$$\
                      Γ"╙M4▒▒b æ  ╙╙╨   $$  _|    $$ |$$ |  $$ | $$$$$$$ |$$ |  $$ |$$ /      $$$$$$$$ |
                                        $$ |      $$ |$$ |  $$ |$$  __$$ |$$ |  $$ |$$ |      $$   ____|
                                    $$\ $$ |      $$ |$$ |  $$ |\$$$$$$$ |$$ |  $$ |\$$$$$$$\ \$$$$$$$\ 
                                    \__|\__|      \__|\__|  \__| \_______|\__|  \__| \_______| \_______|
 
*////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DirtyFinance is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private constant NAME = "dirty.finance";
    string private constant SYMBOL = "DIRTY";
    uint8 private constant DECIMALS = 18;

    mapping(address => uint256) private rewards;
    mapping(address => uint256) private actual;
    mapping(address => mapping(address => uint256)) private allowances;

    mapping(address => bool) private excludedFromFees;
    mapping(address => bool) private excludedFromRewards;
    address[] private rewardExcluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant ACTUAL_TOTAL = 1000000 * 10**6 * 10**18;  //1 Trillion
    uint256 private rewardsTotal = (MAX - (MAX % ACTUAL_TOTAL));
    uint256 private holderFeeTotal;
    uint256 private regenFeeTotal;
    uint256 private burnFeeTotal;

    //dev reward wallets
    //1% admin, 2% holders and 2% burn
    uint256 public taxPercentage = 5;     
    uint256 public holderTaxAlloc = 20;   
    uint256 public regenTaxAlloc = 10;  
    uint256 public burnTaxAlloc = 20;      
    uint256 public totalTaxAlloc = regenTaxAlloc.add(holderTaxAlloc).add(burnTaxAlloc);

    address public regenAddress;
    address public burnAddress;

    constructor(address _regenAddress) {
        rewards[_regenAddress] = rewardsTotal;
        emit Transfer(address(0), _regenAddress, ACTUAL_TOTAL);

        regenAddress = _regenAddress;

        excludeFromRewards(_msgSender());
        excludeFromFees(_regenAddress);

        if (_regenAddress != _msgSender()) {
            excludeFromRewards(_regenAddress);
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
        return holderFeeTotal.add(regenFeeTotal).add(burnFeeTotal);
    }

    function totalHolderFees() external view returns (uint256) {
        return holderFeeTotal;
    }

    function totalRegenFees() external view returns (uint256) {
        return regenFeeTotal;
    }

    function totalBurnFees() external view returns (uint256) {
        return burnFeeTotal;
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
            uint256 regenFee = _getRegenFee(fee);
            uint256 burnFee = _getBurnFee(fee);

            _updateRegenFee(regenFee);
            _updateBurnFee(burnFee);
            
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

    function _updateRegenFee(uint256 _regenFee) private {
        if (regenAddress == address(0)) {
            return;
        }

        uint256 rewardsRate = _getRewardsRate();
        uint256 rewardRegenFee = _regenFee.mul(rewardsRate);
        regenFeeTotal = regenFeeTotal.add(_regenFee);

        rewards[regenAddress] = rewards[regenAddress].add(rewardRegenFee);
        if (excludedFromRewards[regenAddress]) {
            actual[regenAddress] = actual[regenAddress].add(_regenFee);
        }
    }

    function _updateBurnFee(uint256 _burnFee) private {
        if (burnAddress == address(0)) {
            return;
        }

        uint256 rewardsRate = _getRewardsRate();
        uint256 rewardBurnFee = _burnFee.mul(rewardsRate);
        burnFeeTotal = burnFeeTotal.add(_burnFee);

        rewards[burnAddress] = rewards[burnAddress].add(rewardBurnFee);
        if (excludedFromRewards[burnAddress]) {
            actual[burnAddress] = actual[burnAddress].add(_burnFee);
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

    function _getRegenFee(uint256 _tax) private view returns (uint256) {
        return _tax.mul(regenTaxAlloc).div(totalTaxAlloc);
    }

    function _getBurnFee(uint256 _tax) private view returns (uint256) {
        return _tax.mul(burnTaxAlloc).div(totalTaxAlloc);
    }


    function setTaxPercentage(uint256 _taxPercentage) external onlyOwner {
        require(_taxPercentage >= 1 && _taxPercentage <= 10, "Value is outside of range 1-10");
        taxPercentage = _taxPercentage;
    }

    function setTaxAllocations(
        uint256 _holderTaxAlloc,
        uint256 _regenTaxAlloc,
        uint256 _burnTaxAlloc
        
    ) external onlyOwner {
        totalTaxAlloc = _holderTaxAlloc.add(_regenTaxAlloc).add(_burnTaxAlloc);

        require(_holderTaxAlloc >= 5 && _holderTaxAlloc <= 20, "_holderTaxAlloc is outside of range 5-20");
        require(_burnTaxAlloc >= 5 && _burnTaxAlloc <= 20, "_burnTaxAlloc is outside of range 5-20");
        require(_regenTaxAlloc <= 10, "_regenTaxAlloc is greater than 10");
        

        holderTaxAlloc = _holderTaxAlloc;
        regenTaxAlloc = _regenTaxAlloc;
        burnTaxAlloc = _burnTaxAlloc;
        
    }

    function setRegenAddress(address _regenAddress) external onlyOwner {
        regenAddress = _regenAddress;
    }

    function setBurnAddress(address _burnAddress) external onlyOwner {
        burnAddress = _burnAddress;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}