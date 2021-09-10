// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";

import "./MochiRewardToken.sol";
import "./Errors.sol";
import "./IAddressesProvider.sol";
import "./INFTList.sol";

/**
 * @title Vault contract
 * @dev The Vault of Market Market
 * - Holds fees are earned from transactions of the Market
 * - Owned by MochiLab
 * @author MochiLab
 **/

contract Vault is Initializable, ReentrancyGuard {
    uint256 public constant SAFE_NUMBER = 1e12;

    IAddressesProvider public addressesProvider;
    INFTList public nftList;

    // MochiLab tokens balance
    // token address => fund
    mapping(address => uint256) internal _mochiFund;

    // Royalty of NFT Contract, will be paid to owner of NFT Contract
    // nftAddress => token address => amount royalty
    mapping(address => mapping(address => uint256)) internal _nftToRoyalty;
    mapping(address => address) internal _beneficiary;

    // RewardToken corresponding to each Token
    // token addres => rewardToken address
    mapping(address => address) internal _tokenToRewardToken;

    // User's reward token balance
    // user address => rewardToken address => balance
    mapping(address => mapping(address => uint256)) internal _rewardTokenBalance;

    // Duration of a halving cycle of a reward event
    uint256 internal _periodOfCycle;
    // The maximum number of halving of the reward event
    uint256 internal _numberOfCycle;
    // Reward event start time
    uint256 internal _startTime;
    // Reward rate of the first cycle of the reward event
    uint256 internal _firstRate;
    // Reward event is available
    bool internal _rewardIsActive;

    // Royalty numerator
    uint256 internal _royaltyNumerator;
    // Royalty denominator
    uint256 internal _royaltyDenominator;

    event Initialized(
        address indexed provider,
        uint256 numerator,
        uint256 denominator,
        string nativeToken
    );
    event RoyaltyUpdated(uint256 numerator, uint256 denominator);
    event WithdrawFund(address indexed token, uint256 amount, address indexed receiver);
    event Deposit(
        address indexed nftAddress,
        address indexed seller,
        address indexed buyer,
        uint256 amount,
        address token
    );
    event ClaimRoyalty(
        address indexed nftAddress,
        address indexed token,
        uint256 amount,
        address indexed receiver
    );
    event SetupRewardParameters(
        uint256 periodOfCycle,
        uint256 numberOfCycle,
        uint256 startTime,
        uint256 firstRate
    );

    event WithdrawRewardToken(
        address indexed user,
        address indexed rewardToken,
        uint256 amount,
        address indexed receiver
    );

    modifier onlyMarketAdmin() {
        require(addressesProvider.getAdmin() == msg.sender, Errors.CALLER_NOT_MARKET_ADMIN);
        _;
    }

    modifier onlyMarket() {
        require(addressesProvider.getMarket() == msg.sender, Errors.CALLER_NOT_MARKET);
        _;
    }

    /**
     * @dev Function is invoked by the proxy contract when the Vault contract is added to the
     * AddressesProvider of the market.
     * - Caching the address of the AddressesProvider in order to reduce gas consumption
     *   on subsequent operations
     * @param provider The address of the AddressesProvider
     * @param numerator The royalty numerator
     * @param denominator The royalty denominator
     **/
    function initialize(
        address provider,
        uint256 numerator,
        uint256 denominator,
        string memory nativeToken
    ) external initializer {
        require(denominator >= numerator, Errors.DEMONINATOR_NOT_GREATER_THAN_NUMERATOR);

        _royaltyNumerator = numerator;
        _royaltyDenominator = denominator;
        addressesProvider = IAddressesProvider(provider);
        nftList = INFTList(addressesProvider.getNFTList());

        string memory name = string(abi.encodePacked("rMOCHI for: ", nativeToken));
        string memory symbol = string(abi.encodePacked("rMOCHI_", nativeToken));

        MochiRewardToken rewardTokenForNativeToken = new MochiRewardToken(name, symbol);
        _tokenToRewardToken[address(0)] = address(rewardTokenForNativeToken);

        emit Initialized(provider, numerator, denominator, nativeToken);
    }

    function setupRewardToken(address token) external onlyMarket {
        if (_tokenToRewardToken[token] == address(0)) {
            string memory name = string(abi.encodePacked("rMOCHI for ", ERC20(token).name()));
            string memory symbol = string(abi.encodePacked("rMOCHI_", ERC20(token).symbol()));
            MochiRewardToken newReward = new MochiRewardToken(name, symbol);
            _tokenToRewardToken[token] = address(newReward);
        }
    }

    function setBeneficiary(address nftAddress, address beneficiary) external onlyMarketAdmin {
        _beneficiary[nftAddress] = beneficiary;
    }

    /**
     * @dev Deposit fee that Market receives the transaction of the user
     * - Can only be called by Market
     * @param nftAddress The address of nft
     * @param seller The address of seller
     * @param buyer The address of buyer
     * @param amount The amount that Market deposit
     * @param token The token that Market deposit
     */
    function deposit(
        address nftAddress,
        address seller,
        address buyer,
        address token,
        uint256 amount
    ) external payable onlyMarket {
        require(amount > 0, Errors.AMOUNT_IS_ZERO);
        if (token == address(0)) {
            require(amount == msg.value, Errors.NOT_ENOUGH_MONEY);
        } else {
            ERC20(token).transferFrom(msg.sender, address(this), amount);
        }

        uint256 forRoyalty = _calculateRoyalty(amount);

        if (forRoyalty > 0) {
            _nftToRoyalty[nftAddress][token] = _nftToRoyalty[nftAddress][token] + forRoyalty;
        }

        _mochiFund[token] = _mochiFund[token] + (amount - forRoyalty);

        if (_rewardIsActive == true) {
            uint256 currentRate = getCurrentRate();
            uint256 rewardTokenAmount = (amount * currentRate) / 1e18;
            if (rewardTokenAmount > 0) {
                address rewardToken = _tokenToRewardToken[token];
                _rewardTokenBalance[seller][rewardToken] =
                    _rewardTokenBalance[rewardToken][seller] +
                    rewardTokenAmount;
                _rewardTokenBalance[buyer][rewardToken] =
                    _rewardTokenBalance[rewardToken][seller] +
                    rewardTokenAmount;
            }
        }

        emit Deposit(nftAddress, seller, buyer, amount, token);
    }

    /**
     * @dev Withdraw MochiLab Fund
     * - Can only be called by market admin]
     * @param token The token that admin wants to withdraw
     * @param amount The amount that admin wants to withdraw
     * @param receiver The address of receiver
     */
    function withdrawFund(
        address token,
        uint256 amount,
        address payable receiver
    ) external onlyMarketAdmin nonReentrant {
        require(amount <= _mochiFund[token], Errors.INSUFFICIENT_BALANCE);

        _mochiFund[token] = _mochiFund[token] - amount;

        if (token == address(0)) {
            receiver.transfer(amount);
        } else {
            ERC20(token).transfer(receiver, amount);
        }

        emit WithdrawFund(token, amount, receiver);
    }

    /**
     * @dev Claim royalty
     * - Can only be called by owner of nft contract
     * @param nftAddress The address of nft
     * @param token The token that contract owner wants to withdraw
     * @param amount The amount that contract owner to withdraw
     * @param receiver The address of receiver
     */
    function claimRoyalty(
        address nftAddress,
        address token,
        uint256 amount,
        address payable receiver
    ) external nonReentrant {
        require(_nftToRoyalty[nftAddress][token] >= amount, Errors.INSUFFICIENT_BALANCE);

        if (_beneficiary[nftAddress] != address(0)) {
            require(_beneficiary[nftAddress] == msg.sender, Errors.INVALID_BENEFICIARY);
        } else {
            NFTInfoType.NFTInfo memory info = nftList.getNFTInfo(nftAddress);
            require(info.registrant == msg.sender, Errors.INVALID_BENEFICIARY);
        }

        _nftToRoyalty[nftAddress][token] = _nftToRoyalty[nftAddress][token] - amount;

        if (token == address(0)) {
            receiver.transfer(amount);
        } else {
            ERC20(token).transfer(receiver, amount);
        }

        emit ClaimRoyalty(nftAddress, token, amount, receiver);
    }

    /**
     * @dev Withdraw reward token
     * - Can only be called by anyone
     * @param rewardToken The token that user wants to withdraw
     * @param amount The amount that user wants to withdraw
     * @param receiver The address of receiver
     */
    function withrawRewardToken(
        address rewardToken,
        uint256 amount,
        address receiver
    ) external nonReentrant {
        require(
            _rewardTokenBalance[msg.sender][rewardToken] >= amount && amount >= 0,
            Errors.INSUFFICIENT_BALANCE
        );

        _rewardTokenBalance[msg.sender][rewardToken] =
            _rewardTokenBalance[msg.sender][rewardToken] -
            amount;

        MochiRewardToken(rewardToken).mint(receiver, amount);

        emit WithdrawRewardToken(msg.sender, rewardToken, amount, receiver);
    }

    function setupRewardParameters(
        uint256 periodOfCycle,
        uint256 numberOfCycle,
        uint256 startTime,
        uint256 firstRate
    ) external onlyMarketAdmin {
        require(periodOfCycle > 0, Errors.PERIOD_MUST_BE_GREATER_THAN_ZERO);
        require(block.timestamp <= startTime, Errors.INVALID_START_TIME);
        require(numberOfCycle > 0, Errors.NUMBER_OF_CYCLE_MUST_BE_GREATER_THAN_ZERO);
        require(firstRate > 0, Errors.FIRST_RATE_MUST_BE_GREATER_THAN_ZERO);

        _periodOfCycle = periodOfCycle;
        _numberOfCycle = numberOfCycle;
        _startTime = startTime;
        _firstRate = firstRate;
        _rewardIsActive = true;

        emit SetupRewardParameters(periodOfCycle, numberOfCycle, startTime, firstRate);
    }

    function updateRoyaltyParameters(uint256 numerator, uint256 denominator)
        external
        onlyMarketAdmin
    {
        require(denominator >= numerator, Errors.DEMONINATOR_NOT_GREATER_THAN_NUMERATOR);

        _royaltyNumerator = numerator;
        _royaltyDenominator = denominator;

        emit RoyaltyUpdated(numerator, denominator);
    }

    function getCurrentRate() public view returns (uint256) {
        uint256 currentPeriod = getCurrentPeriod();

        if (currentPeriod == 0) {
            return _firstRate;
        } else if (2**currentPeriod > _firstRate || currentPeriod > _numberOfCycle) {
            return 0;
        } else {
            return _firstRate / (2**currentPeriod);
        }
    }

    function getCurrentPeriod() public view returns (uint256) {
        return (block.timestamp - _startTime) / _periodOfCycle;
    }

    function getRewardToken(address token) external view returns (address) {
        return _tokenToRewardToken[token];
    }

    function getRoyalty(address nftAddress, address token) external view returns (uint256) {
        return _nftToRoyalty[nftAddress][token];
    }

    function getRewardTokenBalance(address user, address rewardToken)
        external
        view
        returns (uint256)
    {
        return _rewardTokenBalance[user][rewardToken];
    }

    function getMochiFund(address token) external view returns (uint256) {
        return _mochiFund[token];
    }

    function getRoyaltyParameters() external view returns (uint256, uint256) {
        return (_royaltyNumerator, _royaltyDenominator);
    }

    function checkRewardIsActive() external view returns (bool) {
        if (_rewardIsActive == false) {
            return _rewardIsActive;
        } else {
            return (getCurrentRate() >= 0);
        }
    }

    function _calculateRoyalty(uint256 amount) internal view returns (uint256) {
        uint256 royaltyAmount = ((amount * SAFE_NUMBER * _royaltyNumerator) / _royaltyDenominator) /
            SAFE_NUMBER;
        return royaltyAmount;
    }
}