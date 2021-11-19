// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Context.sol";
import "./ERC677Receiver.sol";
import "./ERC677.sol";
import "./SafeERC677.sol";
import "./IERC677.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./IWETH.sol";
import "./SafeMathChainlink.sol";
import "./AggregatorV3Interface.sol";

contract BtclSeedRound is Context, ReentrancyGuard {
    using SafeMathChainlink for uint256;
    using SafeERC677 for IERC677;

    event TokensPurchased(address purchaser, uint256 btclAmount, uint256 usdAmount);
    event DepositedTokens(address from, uint256 value, bytes data);

    IERC677 public btclToken;
    address payable public wallet;
    address payable public bonus;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address  DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    
    struct UserInfo {
        uint256 totalLockedBTCL;      // Total BTCL Tokens left to be released
        uint256 totalClaimedBTCL;     // Total BTCL Tokens Claimed 
        uint256 totalUSDContributed;  // Total USD Contribution in decimals
        uint256 totalContributions;   // Total Unique Contributions
        uint256 lastRewardBlock;      // Last Block when Tokens were Claimed
    }
    
    struct UserContribution {
        address token;                // Individual Token Address
        uint256 time;                 // Individual Contribution Timestamp
        uint256 tokenInUSD;           // Individual Token USD Value
        uint256 tokenAmount;          // Individual Token Contribution
        uint256 btclToDistribute;     // Individual BTCL Tokens to be distributed
    }

    uint256 public kycUsdLimit = 1500000;       // Max Contribution $15K with 2 extra decimals for precision
    uint256 public kycLimitUplifted = 5000000;  // Max Contribution $50K with 2 extra decimals for precision
    uint256 public startBlock = 13656111;       // https://etherscan.io/block/countdown/13656111 (~21 Nov 2021 UTC = 04:00AM)
    uint256 public endBlock = 13915000;         // https://etherscan.io/block/countdown/13915000 (~1 Jan 2022 UTC = 00:00AM)
    uint256 public cliffEndingBlock = 14777777; // https://etherscan.io/block/countdown/14777777 (~15 May 2022 UTC = 00:00AM)
    uint256 public blocksPerMonth = 200000;
    uint256 public btclDistributed;
    uint256 public totalRaised;
    uint256 public totalBtclClaimed;
    uint256 public uniqueContributors;
    uint256 public uniqueContributions;
    uint256[12] public vestingSchedules;
    uint256[12] public vestingPercentages = [24,5,5,5,5,5,5,5,5,12,12,12];
    
    mapping(uint256 => address) public uniqueAddress;
    mapping(address => bool) private isUnique;
    mapping(address => bool) private kyc;
    mapping(address => bool) private kycUplifted;
    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(uint256 => UserContribution)) public userContribution;
    mapping(address => mapping(uint256 => uint256)) public totalBTCL;
    mapping(address => address) public tokensAndFeeds;

    /**
     * @dev Team Multisig Wallet Modifier
     */
    modifier onlyTeam() {
        require(wallet == _msgSender(), "Only the team wallet can run this function");
        _;
    }
    
    /*
     * Bitcoin Lottery - Seed Round
     * @param _assets the list of accepted tokens
     * @param _priceOracles the list of price feeds
     */
    constructor(IERC677[] memory _assets, address[] memory _priceOracles) public {
        wallet = _msgSender();
        
        for(uint256 i = 0; i < _priceOracles.length; i++) {
            tokensAndFeeds[address(_assets[i])] = _priceOracles[i];
        }
        
        for(uint256 i = 0; i < vestingPercentages.length; i++) {
            vestingSchedules[i] = cliffEndingBlock.add(blocksPerMonth.mul(i));
        }
    }

    /*
     * Aggregate the value for whitelisted tokens.
     * @param _asset the token to be contributed.
     * @param _amount the amount of the token contribution.
     * @return totalUSD and toContribute and toDistribute 
     */
    function getTokenExchangeRate(address _asset, uint256 _amount) public view returns (uint256 totalUSD, uint256 toContribute, uint256 toDistribute) {
        if(_asset == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) { _asset = WETH; } // eth price feed fix
        else { require(tokensAndFeeds[_asset] != address(0), "Asset must be whitelisted"); } // other whitelisted asset price feeds
        
        (, int256 price_token, , , ) = AggregatorV3Interface(tokensAndFeeds[_asset]).latestRoundData();
        (, int256 price_dai, , , ) = AggregatorV3Interface(tokensAndFeeds[DAI]).latestRoundData();

        toContribute = _amount;
        
        if(_asset == USDT || _asset == USDC) {
            totalUSD = _amount.div(10000); // with 2 extra decimals
            toDistribute = totalUSD.mul(666666666666666666); // 0,66 BTCL for 1 cent
        } else if (_asset == DAI) {
            totalUSD = _amount.div(10000000000000000); // with 2 extra decimals
            toDistribute = totalUSD.mul(666666666666666666); // 0,66 BTCL for 1 cent
        } else {
            uint256 tokenDecimals = uint256(10 ** uint256(IERC677(_asset).decimals()));
            uint256 tokenValueInUSD = uint256(price_token).div(uint256(price_dai));
            uint256 tokenOneDollarWorth = tokenDecimals.div(tokenValueInUSD);
            totalUSD = _amount.mul(100).div(tokenOneDollarWorth); // with 2 extra decimals
            toDistribute = totalUSD.mul(666666666666666666); // 0.66 BTCL for 1 cent
        }
    }
    
    /**
     * @dev Contribute with ETH directly
     */
    receive() external payable {
        buyTokensWithETH(_msgSender());
    }

    /*
     * Contribute with ETH directly.
     * @param _beneficiary the contributors address.
     * @return success Contribution succeeded or failed.
     */
    function buyTokensWithETH(address _beneficiary) public payable nonReentrant returns (bool success) {
        require(kyc[_msgSender()] == true && _msgSender() == _beneficiary, "Only Whitelisted addresses are allowed to participate in the Seed Round.");
        
        (uint256 totalUSD, uint256 toContribute, uint256 toDistribute) = getTokenExchangeRate(WETH, msg.value);

        _createPayment(_msgSender(), 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, totalUSD, toContribute, toDistribute);
        
        return true;
    }
    
    /*
     * Contribute with any of the Whitelisted Tokens (WBTC/WETH/LINK/UNI/DAI/USDC/USDT).
     * @param _asset the token used to make the contribution.
     * @param _value the value to be contributed.
     * @return success Contribution succeeded or failed.
     */
    function buyTokens(address _asset, uint256 _value) public nonReentrant returns (bool success) {
        require(kyc[_msgSender()] == true, "Only Whitelisted addresses are allowed to participate in the Seed Round.");

        (uint256 totalUSD, uint256 toContribute, uint256 toDistribute) = getTokenExchangeRate(_asset, _value);
        
        _createPayment(_msgSender(), _asset, totalUSD, toContribute, toDistribute);
    
        return true;
    }
    
    /*
     * Helper function to create the contribution and set BTCL Token Vesting & Distribution Emissions.
     * @param beneficiary The address of the Contributor.
     * @param asset The token used to Contribute.
     * @param value The total amount in USD Contributed.
     */
    function _createPayment(address _beneficiary, address _asset, uint256 _value, uint256 toContribute, uint256 toDistribute) private {
        checkKycDepositLimit(_beneficiary, _value);

        makeContribution(_beneficiary, _asset, toContribute);

        splitTokensInStages(toDistribute);
        
        hydrateContribution(_beneficiary, _asset, toContribute, toDistribute, _value); 
        
        checkUnique();
        
        // EMIT & RETURN TRUE IF CONTRIBUTION SUCCEEDED
        emit TokensPurchased(_beneficiary, toDistribute, _value);
    }

    /**
     * KYC helper function that checks USD Contribution limits.
     * @param _beneficiary the address of the contributor.
     * @param _value the amount contributed.
     */
    function checkKycDepositLimit(address _beneficiary, uint256 _value) private view {
        require(block.number >= startBlock && block.number <= endBlock && btclDistributed < 250000000 * 1e18, "Seed Round finished successfully. Congrats to everyone!");
        require(_value >= 10000, "Contribution amount must be atleast 100$");
        
        UserInfo storage user = userInfo[_beneficiary];
        
        // check if KYC Limit is 15K or 50K and if it was already reached.
        uint256 newUSDValue = user.totalUSDContributed.add(_value);
        
        if(kycUplifted[_beneficiary] == true) {
            require(newUSDValue <= kycLimitUplifted, "Address can't contribute more than 50K USD.");
        } else {
            require(newUSDValue <= kycUsdLimit, "Address can't contribute more than 15K USD.");    
        }

    }
        
    /**
     * KYC helper function to make either ETH or Tokens Contribution
     * @param _beneficiary the address of the contributor.
     * @param _asset the amount contributed.
     * @param toContribute the amount contributed.
     */
    function makeContribution(address _beneficiary, address _asset, uint256 toContribute) private {
        if(_asset == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            wallet.transfer(msg.value);
        } else {
            makeTokenContribution(_beneficiary, _asset, toContribute);
        }
    }
    
    /**
     * Helper function that checks token allowance and makes the contribution.
     * @param _beneficiary the address of the contributor.
     * @param _asset the asset used to contribute.
     * @param _toContribute the amount contributed.
     */
    function makeTokenContribution(address _beneficiary, address _asset, uint256 _toContribute) private {
        uint256 allowance = IERC677(_asset).allowance(_beneficiary, address(this));
        require(allowance >= _toContribute, "Check the token allowance");
        IERC677(_asset).safeTransferFrom(_beneficiary, wallet, _toContribute);
    }
    
    /**
     * Helper function that split BTCL Tokens into multiple release stages.
     * @param _toDistribute total BTCL Tokens that will be distributed.
     */
    function splitTokensInStages(uint256 _toDistribute) private {
        uint256 accumulatedTokens;
        for(uint256 i = 0; i < vestingPercentages.length; i++) {
            uint256 storedBTCL = totalBTCL[_msgSender()][i];
            uint256 tempBTCL = _toDistribute.mul(vestingPercentages[i]).div(100);
            accumulatedTokens = accumulatedTokens.add(_toDistribute.mul(vestingPercentages[i]).div(100));
            // run in all stages except the last stage
            if(i != vestingPercentages.length - 1) {
                totalBTCL[_msgSender()][i] = tempBTCL.add(storedBTCL);
            } else {
                // check if there are any dustTokens stuck and add them to final vesting stage.
                uint256 dustTokens = _toDistribute.sub(accumulatedTokens);
                totalBTCL[_msgSender()][i] = tempBTCL.add(storedBTCL).add(dustTokens);
            }
        }
    }
    
    /**
     * Helper function that updates individual and global variables.
     * @param _beneficiary the address of the contributor.
     * @param _asset the asset used to contribute.
     * @param _toContribute the amount contributed.
     * @param _toDistribute total BTCL Tokens that will be distributed.
     * @param _value The total amount in USD Contributed.
     */
    function hydrateContribution(address _beneficiary, address _asset, uint256 _toContribute, uint256 _toDistribute, uint256 _value) private {
        UserInfo storage user = userInfo[_beneficiary];
        UserContribution storage contribution = userContribution[_beneficiary][user.totalContributions];
        
        // HYDRATE USER CONTRIBUTION
        user.totalContributions = user.totalContributions.add(1);
        user.totalLockedBTCL = user.totalLockedBTCL.add(_toDistribute);
        user.totalUSDContributed = user.totalUSDContributed.add(_value);
        
        // TOTAL BTCL TO DISTRIBUTE & TOTAL RAISED IN USD
        btclDistributed = btclDistributed.add(_toDistribute);
        totalRaised = totalRaised.add(_value);
        uniqueContributions = uniqueContributions.add(1);
        
        // HYDRATE INDIVIDUAL CONTRIBUTION
        contribution.token = _asset;
        contribution.time = now;
        contribution.tokenInUSD = _value;
        contribution.tokenAmount = _toContribute;
        contribution.btclToDistribute = _toDistribute;
    }
    
    /*
     * Helper function to help keep track of all contributors onchain
     */
    function checkUnique() private {
        if(isUnique[_msgSender()] == false) { 
            isUnique[_msgSender()] = true;
            uniqueAddress[uniqueContributors] = _msgSender();
            uniqueContributors = uniqueContributors.add(1);
        }
    }
    
    /**
     * Claim unlockable BTCL Tokens based on current vesting stage.
     * @return total BTCL tokens claimed.
     */
    function claimVestedTokens() public nonReentrant returns (uint256 total) {
        uint256 totalBtclLeftToWithdraw;
        
        if(block.number > cliffEndingBlock) {
            
            UserInfo storage user = userInfo[_msgSender()];
        
            for(uint256 i = 0; i < vestingSchedules.length; i++) {
                if (block.number >= vestingSchedules[i]) {
                    uint256 tempBTCL = totalBTCL[_msgSender()][i];
                    totalBtclLeftToWithdraw = totalBtclLeftToWithdraw.add(tempBTCL);
                    user.totalClaimedBTCL = user.totalClaimedBTCL.add(tempBTCL);
                    totalBTCL[_msgSender()][i] = 0;
                    user.lastRewardBlock = block.number;
                    totalBtclClaimed = totalBtclClaimed.add(tempBTCL);
                }
            }
            
            btclToken.safeTransfer(_msgSender(), totalBtclLeftToWithdraw);
        
            return (totalBtclLeftToWithdraw);
        } else {
            revert("The Vesting Cliff Period has not yet passed.");
        }

    }
    
    /**
     * Get tokens unlocked percentage on current stage.
     * @param _contributorAddress the contributor address.
     * @return stage and percent and total Percent of tokens that can be claimed.
     */
    function getTokensUnlockedPercentage(address _contributorAddress) public view returns (uint256 stage, uint256 percentage, uint256 total) {
        uint256 totalLeftToWithdraw;
        uint256 allowedPercent;
        uint256 currentStage;
        
        for(uint8 i = 0; i < vestingSchedules.length; i++) {
            if (block.number >= vestingSchedules[i]) {
                allowedPercent = allowedPercent.add(vestingPercentages[i]);
                currentStage = i;
            }
        }
        
        for(uint256 v = 0; v <= currentStage; v++) {
            if (block.number >= vestingSchedules[currentStage]) {
                uint256 tempBTCL = totalBTCL[_contributorAddress][v];
                totalLeftToWithdraw = totalLeftToWithdraw.add(tempBTCL);
            }
        }
        
        return (currentStage, allowedPercent, totalLeftToWithdraw);
    }

    /**
     * @dev KYC helper function used to display current KYC Status.
     * @param _contributorAddress The Contributor Address Whitelisting Address.
     * @return whitelisted and KYC uplift Status.
     */
    function checkKYC(address _contributorAddress) public view returns (bool whitelisted, bool uplifted) {
        return (kyc[_contributorAddress], kycUplifted[_contributorAddress]);
    }

    /**
     * @dev KYC helper function used by the team to whitelist multiple addresses at once.
     * @param _addresses whitelisted address list.
     * @param _whitelisted whitelisted address can contribute up to $15K.
     * @param _kycUplift whitelisted address owner has provided sources of funds and was uplifted to contribute up to $50K.
     */
    function multiKycWhitelisting(address[] memory _addresses, bool[] memory _whitelisted, bool[] memory _kycUplift) public onlyTeam returns (bool success) {
        for(uint256 i = 0; i < _addresses.length; i++) {
            kyc[_addresses[i]] = _whitelisted[i];
            kycUplifted[_addresses[i]] = _kycUplift[i];
        }
        return true;
    }
    
    /**
     * @dev ChainLink helper function used to update old Chainlink Price Feed Aggregators or add new ones.
     * @param _asset The token associated to the Chainlink Price Feed.
     * @param _newAggregatorAddress The Aggregator Contract Address.
     */
    function updateAggregatorAddress(address _asset, address _newAggregatorAddress) public onlyTeam {
        tokensAndFeeds[_asset] = _newAggregatorAddress;
    }
    
    /**
     * @dev Team helper function used to update old multisig wallet address.
     * @param _newWallet The new team multi signature wallet.
     */
    function updateTeamWalletAddress(address payable _newWallet) public onlyTeam {
        wallet = _newWallet;
    }
    
    /**
     * @dev Team helper function used to update old bonus reserve address.
     * @param _newWallet The new bonus reserve smart contract.
     */
    function updateBonusReserveAddress(address payable _newWallet) public onlyTeam {
        bonus = _newWallet;
    }
    
    /**
     * @dev Team helper function used to upgrade the BTCL Governance Token.
     * Future Upgrades: Gassless DAO Voting, Approval Signatures with no GAS Costs, Merkle Proofs.
     * @param _btclToken The new upgraded BTCL Governance Token.
    */
    function updateBtclTokenAddress(address payable _btclToken) public onlyTeam {
        btclToken = IERC677(_btclToken);
    }
    
    /**
     * @dev Team helper function used to redistribute undistributed BTCL Tokens back into the Community Bonus Reserve.
     */
    function redistributeTokens() public onlyTeam {
        require(block.number >= endBlock, "The Seed Round Contribution period has not yet finished");
        uint256 undistributedBtclTokens = uint256(250000000 * 1e18).sub(btclDistributed);
        btclToken.safeTransfer(bonus, undistributedBtclTokens);
    }

    /**
     * @dev ERC677 TokenFallback Function.
     * @param _wallet The team address can send BTCL tokens to the Seed Round Contract.
     * @param _value The amount of tokens sent by the team to the BTCL Seed Round Contract.
     * @param _data The transaction metadata.
     */
    function onTokenTransfer(address _wallet, uint256 _value, bytes memory _data) public {
        require(_msgSender() == address(btclToken), "Contract only accepts BTCL Tokens");
        require(wallet == _wallet,"Only team wallet is allowed");
        emit DepositedTokens(_wallet, _value, _data);
    }
    
}