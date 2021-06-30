pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "../governance/IGovernanceToken.sol";
import "../governance/IGammaVesting.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "../integration/IWETH.sol";


/**
 * @title GammaCrowdsale
 * @dev Crowdsale contract that sells GAMMA tokens for multiple cryptocurrencies.
 * Contract has start and end time, soft and hard cap denominated in USD.
 * Token price is divided in 3 distinct phases where price increases
 * linearly in each phase. If soft cap is reached, crowdsale is successful, and
 * upon finalization investors receive their tokens. If soft cap is not reached,
 * funds are returned to investors.
 */
contract GammaCrowdsale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    AggregatorV3Interface public _priceFeed;
    IGovernanceToken public _gammaToken;
    IGammaVesting public _vesting;
    IWETH public _weth;

    bool public _isPriceFeedSet;
    bool public _finalized;
    bool private _isSoftCapReached;

    uint256 public _openingTime;
    uint256 public _closingTime;

    // using 18 decimals
    uint256 public constant _softCapInUSD =  1800000000000000000000000;  // $1.8M
    uint256 public constant _midCapInUSD  =  6000000000000000000000000;  // $6M
    uint256 public constant _hardCapInUSD = 12000000000000000000000000;  // $12M

    uint256 public constant _phase1StartPriceInUSD = 10000000000000000;  // $0.01
    uint256 public constant _phase2StartPriceInUSD = 12000000000000000;  // $0.012
    uint256 public constant _phase3StartPriceInUSD = 13000000000000000;  // $0.013
    uint256 public constant _maxPriceInUSD = 13500000000000000;          // $0.0135

    uint256 public _phase1Supply = _softCapInUSD.mul(10 ** 18) / ((_phase2StartPriceInUSD + _phase1StartPriceInUSD) / 2);
    uint256 public _phase2Supply = _phase1Supply + ((_midCapInUSD - _softCapInUSD).mul(10 ** 18) / ((_phase3StartPriceInUSD + _phase2StartPriceInUSD) / 2));
    uint256 public _phase3Supply = _phase2Supply + ((_hardCapInUSD - _midCapInUSD).mul(10 ** 18) / ((_maxPriceInUSD + _phase3StartPriceInUSD) / 2));

    uint256 public _phase1Multiplier = (_phase2StartPriceInUSD - _phase1StartPriceInUSD).mul(10 ** 18) / _phase1Supply;
    uint256 public _phase2Multiplier = (_phase3StartPriceInUSD - _phase2StartPriceInUSD).mul(10 ** 18) / (_phase2Supply - _phase1Supply);
    uint256 public _phase3Multiplier = (_maxPriceInUSD - _phase3StartPriceInUSD).mul(10 ** 18) / (_phase3Supply - _phase2Supply);

    uint256 public _gammaTokensSold;
    uint256 public _currentPriceInUSD = _phase1StartPriceInUSD;
    uint256 public _currentCollectedAmountInETH;
    uint256 public _currentCollectedAmountInUSD;
    // maps currency contract address to decimals
    mapping (address => uint8) public _acceptedCurrencies;
    address[] private _acceptedCurrenciesAddresses;

    // maps user address to a map of token to balance
    mapping(address => mapping(address => uint256)) private _balances;
    mapping(address => uint256) public _gammaBalances;

    // addresses that will receive 70% of GAMMA tokens after successfull crowdsale
    address public _preICOInvestor;
    address public _advisor;
    address public _founder1;
    address public _founder2;
    address public _foundation;
    address public _marketMaker;

    /**
     * @dev Reverts if crowdsale hasn't started.
     */
    modifier onlyBeforeOpening {
        require(block.timestamp < _openingTime, "Only before opening");
        _;
    }

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen(), "Only while open");
        _;
    }

    /**
     * @dev Reverts if crowdsale isn't closed.
     */
    modifier onlyAfterClosing {
        require(hasClosed() || hardCapReached(), "Only after closing");
        _;
    }

    // events
    event CrowdsaleFinalized();
    event AcceptedCurrencySet(address indexed currency, uint8 decimals);
    event TokensPurchased(address indexed beneficiary, address indexed currency, uint256 spendAmount, uint256 gammaAmount);

    /**
     * @dev Creates an instance of GammaVesting.
     * @param gammaToken address of GAMMA token contract
     * @param weth address of Wrapped ETH (WETH) contract
     * @param openingTime timestamp when crowdsale begins (same format as block.timestamp)
     * @param closingTime timestamp when crowdsale ends (same format as block.timestamp)
     * @param preICOInvestor pre-ICO investor address
     * @param advisor advisor address
     * @param founder1 founder1 address
     * @param founder2 founder2 address
     * @param foundation foundation address
     * @param marketMaker market maker address
     */
    constructor (
        IGovernanceToken gammaToken,
        // IGammaVesting vesting,
        IWETH weth,
        uint256 openingTime,
        uint256 closingTime,
        address preICOInvestor,
        address advisor,
        address founder1,
        address founder2,
        address foundation,
        address marketMaker
    ) public {
        _gammaToken = gammaToken;
        // _vesting = vesting;
        _weth = weth;
        _openingTime = openingTime;
        _closingTime = closingTime;
        // TODO: izvesno je da cemo imati vise od jednog pre-ICO investora
        _preICOInvestor = preICOInvestor;
        _advisor = advisor;
        _founder1 = founder1;
        _founder2 = founder2;
        _foundation = foundation;
        _marketMaker = marketMaker;

        _isPriceFeedSet = false;
        _finalized = false;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        return block.timestamp > _closingTime;
    }

    /**
     * @return true if the crowdsale is finalized, false otherwise.
     */
    function finalized() public view returns (bool) {
        return _finalized;
    }

    /**
     * @dev Checks whether funding soft cap was reached. Soft cap can
     * @return Whether funding soft cap was reached
     */
    function softCapReached() public view returns (bool) {
        return _isSoftCapReached || (getCurrentCollectedAmountInUSD() >= _softCapInUSD);
    }

    /**
     * @dev Checks whether funding hard cap was reached.
     * @return Whether funding hard cap was reached
     */
    function hardCapReached() public view returns (bool) {
        return (_gammaTokensSold >= _phase3Supply || _currentPriceInUSD >= _maxPriceInUSD);
    }

    /**
     * @dev Adds/Sets accepted currency and decimal places. Can override existing record.
     * Can be called by owner only.
     * @param currency address of cryptocurrency contract
     * @param decimals decimal places of given currency
     */
    function setAcceptedCurrency(address currency, uint8 decimals) external onlyOwner onlyBeforeOpening {
        // TODO: don't forget to set WETH as accepted currency
        _acceptedCurrencies[currency] = decimals;
        _acceptedCurrenciesAddresses.push(currency);

        emit AcceptedCurrencySet(currency, decimals);
    }

    /**
     * @dev Sets the Chainlink price feed for USDC/ETH price
     * @param priceFeedAddress address of the Chainlink price feed for USDC/ETH price
     */
    function setPriceFeed(address priceFeedAddress) external onlyOwner onlyBeforeOpening {
        require(!_isPriceFeedSet, "Not allowed to change price feed");
        _priceFeed = AggregatorV3Interface(priceFeedAddress);
        _isPriceFeedSet = true;
    }

    /**
     * @dev Gets purchased GAMMA tokens for a buyer
     * @param buyer address that bought GAMMA tokens
     */
     // TODO: _gammaBalances is public so you practically have 2 functions for the same thing. Either eraze this, or make _gammaBalances private
    function getGAMMABalance(address buyer) external view returns(uint256){
        return _gammaBalances[buyer];
    }

    /**
     * @dev Allowes admin to withdraw funds if the soft cap is reached and crowdsale is deamed successful
     * @param currency address of one of the accepted currencies that is being withdrawn
     * @param amount amount of funds that is being withdrawn
     */
    function withdraw(address currency, uint256 amount) external onlyOwner {
        require(_acceptedCurrencies[currency] != 0, "Accepted currencies only");

        if (softCapReached()) {
            TransferHelper.safeTransfer(currency, msg.sender, amount);
            if (currency == address(_weth)) {
                _currentCollectedAmountInETH = _currentCollectedAmountInETH.sub(amount);
            } else {
                _currentCollectedAmountInUSD = _currentCollectedAmountInUSD.sub(amount);
            }
            _isSoftCapReached = true;
        }
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     */
    function buyGAMMATokensWithETH() public nonReentrant onlyWhileOpen payable {
        require(msg.value > 0, "amount is 0");

        _depositEther(msg.sender, msg.value);
        _issueGammaTokens(msg.value, address(_weth), msg.sender);
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param currency currency used for purchase, must be accepted
     * @param spendAmount token amount (in lowest denomination) that purchaser wants to spend
     */
    function buyGAMMATokens(address currency, uint256 spendAmount) public nonReentrant onlyWhileOpen {
        require(currency != address(0), "currency is the zero address");
        require(_acceptedCurrencies[currency] != 0, "Accepted currencies only");
        require(spendAmount > 0, "spendAmount is 0");

        _depositToken(msg.sender, currency, spendAmount);
        _issueGammaTokens(spendAmount, currency, msg.sender);
    }

    /**
     * @dev Returns the spend amount in USD
     * @param spendAmount amount (in lowest denomination) that purchaser wants to spend
     * @param isWETH is user spending ETH or WETH
     * @param decimals user token decimals
     * @return the value of spendAmount in USD (with 18 decimals)
     */
    function getUSDAmount(uint256 spendAmount, bool isWETH, uint8 decimals) public view returns (uint256) {
        // ETH or WETH
        if(isWETH) {
            return (spendAmount.mul(getETHPriceInUSD())).div(10 ** 18);
        }

        return (spendAmount.mul(10 ** 18)).div(10 ** uint256(decimals));
    }

    /**
     * @dev Returns the latest price of ETH in USDC
     * @return the latest price of ETH in USDC
     */
    function getETHPriceInUSD() public view returns (uint256) {
        (, int price,,,) = _priceFeed.latestRoundData();
        uint8 decimals = _priceFeed.decimals();
        return (uint256(price).mul(10 ** 18)).div(10 ** uint256(decimals));
    }

    /**
     * @dev Returns current amount of collected funds in USD
     * @return currentCollectedAmountInUSD Current amount of collected funds in USD
     */
    function getCurrentCollectedAmountInUSD() public view returns (uint256 currentCollectedAmountInUSD) {
        uint256 collectedAmountOfWETHInUSD = getUSDAmount(_currentCollectedAmountInETH, true, _acceptedCurrencies[address(_weth)]);
        currentCollectedAmountInUSD = collectedAmountOfWETHInUSD.add(_currentCollectedAmountInUSD);
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */
    function finalize() public onlyAfterClosing {
        require(!_finalized, "Crowdsale already finalized");

        _finalized = true;

        // if goal reached, distribute initial token funds
        if (softCapReached()) {
            uint256 preICOInvestorAmount = (_gammaTokensSold.mul(10)).div(30);
            uint256 advisorAmount = (_gammaTokensSold.mul(75)).div(300);
            uint256 founder1Amount = (_gammaTokensSold.mul(175)).div(300);
            uint256 founder2Amount = (_gammaTokensSold.mul(175)).div(300);
            uint256 foundationAmount = (_gammaTokensSold.mul(125)).div(300);
            uint256 marketMakerAmount = (_gammaTokensSold.mul(5)).div(30);

            _gammaToken.mint(_preICOInvestor, preICOInvestorAmount);
            _gammaToken.mint(_advisor, advisorAmount);
            _gammaToken.mint(_founder1, founder1Amount);
            _gammaToken.mint(_founder2, founder2Amount);
            _gammaToken.mint(_foundation, foundationAmount);
            _gammaToken.mint(_marketMaker, marketMakerAmount);
        }

        emit CrowdsaleFinalized();
    }

    /**
     * @dev Withdraw tokens only after crowdsale ends. This method is for the investors.
     * @param beneficiary Whose tokens will be withdrawn.
     */
    function withdrawGammaTokens(address beneficiary) public {
        require(_finalized, "Crowdsale not finalized");
        require(softCapReached(), "Goal not reached");

        _gammaToken.mint(beneficiary, _gammaBalances[beneficiary]);
    }

    /**
     * @dev Investors can claim refunds here if crowdsale is unsuccessful. This method is for the investors.
     * @param refundee Whose refund will be claimed.
     */
    function claimRefund(address refundee) public {
        require(_finalized, "Crowdsale not finalized");
        require(!softCapReached(), "Goal reached");

        for(uint8 i = 0; i < _acceptedCurrenciesAddresses.length; i++) {
            if (_balances[_acceptedCurrenciesAddresses[i]][refundee] > 0) {
                TransferHelper.safeTransfer(_acceptedCurrenciesAddresses[i], refundee, _balances[_acceptedCurrenciesAddresses[i]][refundee]);
                _balances[_acceptedCurrenciesAddresses[i]][refundee] = 0;
            }
        }
    }

    /**
     * @dev Calculates the amount of tokens to be released for the input amount of USD with 18 decimals
     * @param amount Value in USD with 18 decimals to be converted into tokens
     * @return gammaTokenAmount Number of tokens that can be purchased with the specified amount
     * @return nextPriceInUSD Next price of GAMMA tokens after this purchase
     */
    function getGammaTokenAmount(uint256 amount) public view returns (uint256 gammaTokenAmount, uint256 nextPriceInUSD) {
        gammaTokenAmount = 0;
        uint256 currentPriceInUSD = _currentPriceInUSD;
        // phase 1
        if(currentPriceInUSD < _phase2StartPriceInUSD) {
            nextPriceInUSD = getNextPrice(amount, currentPriceInUSD, _phase1Multiplier);
            if (nextPriceInUSD >= _phase2StartPriceInUSD) {
                // gammaTokenAmount = _phase1Supply.sub(_gammaTokensSold); // TODO: check if _gammaTokensSold in phase1 can be > _phase1Supply due to the rounding in sqrt (test case - buy for USD 1,799,999 and then buy for USD 1)
                // amount = amount.sub((gammaTokenAmount.mul(currentPriceInUSD.add(_phase2StartPriceInUSD) / 2)).div(10 ** 18));

                // protection against potential error produced by rounding in babyloninan sqrt
                gammaTokenAmount = ((_phase2StartPriceInUSD.sub(currentPriceInUSD)).mul(10 ** 18)).div(_phase1Multiplier);
                uint256 phase1Amount = (gammaTokenAmount.mul(currentPriceInUSD.add(_phase2StartPriceInUSD) / 2)).div(10 ** 18);
                amount = (amount > phase1Amount) ? amount.sub(phase1Amount) : 0;
                currentPriceInUSD = _phase2StartPriceInUSD;
            } else {
                gammaTokenAmount = (amount.mul(2 * 10 ** 18)).div((currentPriceInUSD.add(nextPriceInUSD)));
            }
        }
        // phase 2
        if(currentPriceInUSD >= _phase2StartPriceInUSD && currentPriceInUSD < _phase3StartPriceInUSD) { // TODO: Test scenario when user jumps from phase 1 to phase 3
            nextPriceInUSD = getNextPrice(amount, currentPriceInUSD, _phase2Multiplier);
            if (nextPriceInUSD >= _phase3StartPriceInUSD) {
                // uint256 gammaTokenAmountPhase2 = _phase2Supply.sub(_gammaTokensSold.add(gammaTokenAmount)); // TODO: check if _gammaTokensSold in phase1 can be > _phase1Supply due to the rounding in sqrt
                // amount = amount.sub((gammaTokenAmountPhase2.mul(currentPriceInUSD.add(_phase3StartPriceInUSD) / 2)).div(10 ** 18));

                // protection against potential error produced by rounding in babyloninan sqrt
                uint256 phase2GammaTokenAmount = ((_phase3StartPriceInUSD.sub(currentPriceInUSD)).mul(10 ** 18)).div(_phase2Multiplier);
                uint256 phase2Amount = (phase2GammaTokenAmount.mul(currentPriceInUSD.add(_phase3StartPriceInUSD) / 2)).div(10 ** 18);
                amount = (amount > phase2Amount) ? amount.sub(phase2Amount) : 0;
                gammaTokenAmount = gammaTokenAmount + phase2GammaTokenAmount;
                currentPriceInUSD = _phase3StartPriceInUSD;
            } else {
                gammaTokenAmount = gammaTokenAmount.add((amount.mul(2 * 10 ** 18)).div((currentPriceInUSD.add(nextPriceInUSD))));
            }
        }
        // phase 3
        if(currentPriceInUSD >= _phase3StartPriceInUSD) {
            nextPriceInUSD = getNextPrice(amount, currentPriceInUSD, _phase3Multiplier);
            require(nextPriceInUSD <= _maxPriceInUSD, "Hard cap breach");
            gammaTokenAmount = gammaTokenAmount.add((amount.mul(2 * 10 ** 18)).div((currentPriceInUSD.add(nextPriceInUSD))));
        }
    }

    function getNextPrice(uint256 amount, uint256 currentPriceInUSD, uint256 currentPhaseMultiplier) public pure returns (uint256) {
        uint256 x = (currentPriceInUSD.mul(currentPriceInUSD)).add((currentPhaseMultiplier.mul(amount).mul(2)));
        return sqrt(x);
    }

    // PRIVATE / INTERNAL
    /**
     * @dev Deposits ETH to user balance by transforming it into wrapped ETH.
     * @param sender Address of the sender.
     * @param amount Amount of ETH to be deposited.
     */
    function _depositEther(address sender, uint256 amount) internal {
        // wrap ETH to WETH
        address wethAddress = address(_weth);
        _weth.deposit{value: amount}();

        // update user balance
        _balances[wethAddress][sender] = _balances[wethAddress][sender].add(amount);
    }

    /**
     * @dev Deposits specified token amount to user balance
     * @param sender Address of the sender.
     * @param token Address of the token.
     * @param amount Amount of token to be deposited.
     */
    function _depositToken(address sender, address token, uint256 amount) internal {
        // withdraw tokens from sender to this contract
        TransferHelper.safeTransferFrom(token, sender, address(this), amount);

        // update user balance
        _balances[token][sender] = _balances[token][sender].add(amount);
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _issueGammaTokens(uint256 spendAmount, address currency, address beneficiary) internal {
        bool isWETH = currency == address(_weth);
        // calculate spend amount in 18 decimals USD
        uint256 spendAmountInUSD = getUSDAmount(spendAmount, isWETH, _acceptedCurrencies[currency]);

        // TODO: check if current amount + spendAmount > hard cap

        // calculate GAMMA token amount that user will receive
        (uint256 gammaAmount, uint256 nextPriceInUSD) = getGammaTokenAmount(spendAmountInUSD);

        // TODO: add minter role to this contract

        // issue tokens and update state
        _gammaBalances[beneficiary] = _gammaBalances[beneficiary].add(gammaAmount);
        _gammaTokensSold = _gammaTokensSold.add(gammaAmount);
        _currentPriceInUSD = nextPriceInUSD;
        if (isWETH) {
            _currentCollectedAmountInETH = _currentCollectedAmountInETH.add(spendAmount);
        } else {
            _currentCollectedAmountInUSD = _currentCollectedAmountInUSD.add(spendAmountInUSD);
        }

        if (softCapReached()) {
            _isSoftCapReached = true;
        }

        emit TokensPurchased(beneficiary, currency, spendAmount, gammaAmount);
    }

    /**
     * @dev fallback function to prevent sending ETH directly to this contract.
     */
    receive() external payable {
        revert();
    }
}

pragma solidity ^0.6.0;

interface IGammaVesting {
    function votable(address account) external view returns (uint256);
    function deposited(address account) external view returns (uint256);
}

pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface IGovernanceToken is IERC20 {
    function mint(address account, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
    function getPriorVotes(address account, uint blockNumber) external view returns (uint256);

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);
}

pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);

    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
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