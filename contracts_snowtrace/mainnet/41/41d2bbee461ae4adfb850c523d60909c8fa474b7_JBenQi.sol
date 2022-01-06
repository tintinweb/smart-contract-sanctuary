// SPDX-License-Identifier: MIT
/**
 * Created on 2021-12-15
 * @summary: Jibrel BenQi Tranche Protocol
 * @author: Jibrel Team
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IJAdminTools.sol";
import "./interfaces/IJTrancheTokens.sol";
import "./interfaces/IJTranchesDeployer.sol";
import "./interfaces/IJBenQi.sol";
import "./interfaces/IQiErc20.sol";
import "./interfaces/IComptrollerLensInterface.sol";
import "./JBenQiStorage.sol";
import "./TransferAVAXHelper.sol";
import "./interfaces/IIncentivesController.sol";
import "./interfaces/IJBenQiHelper.sol";


contract JBenQi is OwnableUpgradeable, ReentrancyGuardUpgradeable, JBenQiStorageV2, IJBenQi {
    using SafeMathUpgradeable for uint256;

    /**
     * @dev contract initializer
     * @param _adminTools price oracle address
     * @param _feesCollector fees collector contract address
     * @param _tranchesDepl tranches deployer contract address
     * @param _qiTokenAddress COMP token contract address
     * @param _comptrollAddress comptroller contract address
     * @param _rewardsToken rewards token address (slice token address)
     */
    function initialize(address _adminTools, 
            address _feesCollector, 
            address _tranchesDepl,
            address _qiTokenAddress,
            address _comptrollAddress,
            address _rewardsToken) external initializer() {
        OwnableUpgradeable.__Ownable_init();
        adminToolsAddress = _adminTools;
        feesCollectorAddress = _feesCollector;
        tranchesDeployerAddress = _tranchesDepl;
        qiTokenAddress = _qiTokenAddress;
        trollerAddress = _comptrollAddress;
        rewardsToken = _rewardsToken;
        redeemTimeout = 3; //default
        // totalBlocksPerYear = 2102400; // same number like in BenQi protocol
        totalBlocksPerYear = 31557600; // secondonds in 1 year
    }

    /**
     * @dev admins modifiers
     */
    modifier onlyAdmins() {
        require(IJAdminTools(adminToolsAddress).isAdmin(msg.sender), "!Admin");
        _;
    }

    // This is needed to receive ETH
    fallback() external payable {}
    receive() external payable {}

    /**
     * @dev set constants for JBenQi
     * @param _trNum tranche number
     * @param _redemPerc redemption percentage (scaled by 1e4)
     * @param _redemTimeout redemption timeout, in blocks
     * @param _blocksPerYear blocks per year (31.557.600 seconds in 1 year)
     */
    function setConstantsValues(uint256 _trNum, uint16 _redemPerc, uint32 _redemTimeout, uint256 _blocksPerYear) external onlyAdmins {
        trancheParameters[_trNum].redemptionPercentage = _redemPerc;
        redeemTimeout = _redemTimeout;
        totalBlocksPerYear = _blocksPerYear;
    }

    /**
     * @dev set eth gateway 
     * @param _avaxGateway avaxGateway address
     */
    function setAVAXGateway(address _avaxGateway) external onlyAdmins {
        avaxGateway = IAVAXGateway(_avaxGateway);
    }

    /**
     * @dev set incentive rewards address
     * @param _incentivesController incentives controller contract address
     */
    function setIncentivesControllerAddress(address _incentivesController) external override onlyAdmins {
        incentivesControllerAddress = _incentivesController;
    }

    /**
     * @dev get incentive rewards address
     */
    function getIncentivesControllerAddress() external view override returns (address) {
        return incentivesControllerAddress;
    }

    /**
     * @dev set incentive rewards address
     * @param _helper JBenQi helper contract address
     */
    function setBenQiHelperAddress(address _helper) external onlyAdmins {
        jBenQiHelperAddress = _helper;
    }

    /**
     * @dev set new addresses for price oracle, fees collector and tranche deployer 
     * @param _adminTools price oracle address
     * @param _feesCollector fees collector contract address
     * @param _tranchesDepl tranches deployer contract address
     * @param _qiTokenAddress COMP token contract address
     * @param _comptrollAddress comptroller contract address
     * @param _rewardsToken rewards token address (slice token address)
     */
    function setNewEnvironment(address _adminTools, 
            address _feesCollector, 
            address _tranchesDepl,
            address _qiTokenAddress,
            address _comptrollAddress,
            address _rewardsToken) external onlyOwner {
        require((_adminTools != address(0)) && (_feesCollector != address(0)) && 
            (_tranchesDepl != address(0)) && (_comptrollAddress != address(0)) && (_qiTokenAddress != address(0)), "ChkAddress");
        adminToolsAddress = _adminTools;
        feesCollectorAddress = _feesCollector;
        tranchesDeployerAddress = _tranchesDepl;
        qiTokenAddress = _qiTokenAddress;
        trollerAddress = _comptrollAddress;
        rewardsToken = _rewardsToken;
    }

    /**
     * @dev set relationship between AVAX and the corresponding BenQi qiAVAX contract
     * @param _QiAvaxContract BenQi token contract address
     */
    function setQiAvaxContract(address _QiAvaxContract) external onlyAdmins {
        qiAVAXToken = IQiAvax(_QiAvaxContract);
        qiTokenContracts[address(0)] = _QiAvaxContract;
    }

    /**
     * @dev set relationship between a token and the corresponding BenQi qiToken contract
     * @param _erc20Contract token contract address 
     * @param _QiErc20Contract BenQi token contract address 
     */
    function setQiTokenContract(address _erc20Contract, address _QiErc20Contract) external onlyAdmins {
        qiTokenContracts[_erc20Contract] = _QiErc20Contract;
    }

    /**
     * @dev check if a qiToken is allowed or not
     * @param _erc20Contract token contract address (i.e. DAI contract, on Kovan: 0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa)
     * @return true or false
     */
    function isQiTokenAllowed(address _erc20Contract) public view returns (bool) {
        return qiTokenContracts[_erc20Contract] != address(0);
    }

    /**
     * @dev get RPB from compound
     * @param _trancheNum tranche number
     * @return qiToken compound supply RPB
     */
    function getCompoundSupplyRPB(uint256 _trancheNum) external view returns (uint256) {
        IQiErc20 qiToken = IQiErc20(qiTokenContracts[trancheAddresses[_trancheNum].buyerCoinAddress]);
        return qiToken.supplyRatePerBlock();
    }

    /**
     * @dev check if a qiToken is allowed or not
     * @param _trancheNum tranche number
     * @param _qiTokenDec qiToken decimals
     * @param _underlyingDec underlying token decimals
     */
    function setDecimals(uint256 _trancheNum, uint8 _qiTokenDec, uint8 _underlyingDec) external onlyAdmins {
        require((_qiTokenDec <= 18) && (_underlyingDec <= 18), "Decs");
        trancheParameters[_trancheNum].qiTokenDecimals = _qiTokenDec;
        trancheParameters[_trancheNum].underlyingDecimals = _underlyingDec;
    }

    /**
     * @dev set tranche A fixed percentage (scaled by 1e18)
     * @param _trancheNum tranche number
     * @param _newTrAPercentage new tranche A fixed percentage (scaled by 1e18)
     */
    function setTrancheAFixedPercentage(uint256 _trancheNum, uint256 _newTrAPercentage) external onlyAdmins {
        trancheParameters[_trancheNum].trancheAFixedPercentage = _newTrAPercentage;
        trancheParameters[_trancheNum].storedTrancheAPrice = setTrancheAExchangeRate(_trancheNum);
    }

    /**
     * @dev add tranche in protocol
     * @param _erc20Contract token contract address (0x0000000000000000000000000000000000000000 if eth)
     * @param _nameA tranche A token name
     * @param _symbolA tranche A token symbol
     * @param _nameB tranche B token name
     * @param _symbolB tranche B token symbol
     * @param _fixedRpb tranche A percentage fixed compounded interest per year
     * @param _qiTokenDec qiToken decimals
     * @param _underlyingDec underlying token decimals
     */
    function addTrancheToProtocol(address _erc20Contract, string memory _nameA, string memory _symbolA, string memory _nameB, 
                string memory _symbolB, uint256 _fixedRpb, uint8 _qiTokenDec, uint8 _underlyingDec) external onlyAdmins nonReentrant {
        require(tranchesDeployerAddress != address(0), "!TrDepl");
        require(isQiTokenAllowed(_erc20Contract), "!Allow");

        trancheAddresses[tranchePairsCounter].buyerCoinAddress = _erc20Contract;
        trancheAddresses[tranchePairsCounter].qiTokenAddress = qiTokenContracts[_erc20Contract];
        // our tokens always with 18 decimals
        trancheAddresses[tranchePairsCounter].ATrancheAddress = 
                IJTranchesDeployer(tranchesDeployerAddress).deployNewTrancheATokens(_nameA, _symbolA, tranchePairsCounter);
        trancheAddresses[tranchePairsCounter].BTrancheAddress = 
                IJTranchesDeployer(tranchesDeployerAddress).deployNewTrancheBTokens(_nameB, _symbolB, tranchePairsCounter);
        
        trancheParameters[tranchePairsCounter].qiTokenDecimals = _qiTokenDec;
        trancheParameters[tranchePairsCounter].underlyingDecimals = _underlyingDec;
        trancheParameters[tranchePairsCounter].trancheAFixedPercentage = _fixedRpb;
        trancheParameters[tranchePairsCounter].trancheALastActionBlock = block.timestamp;
        // if we would like to have always 18 decimals
        trancheParameters[tranchePairsCounter].storedTrancheAPrice = 
            IJBenQiHelper(jBenQiHelperAddress).getBenQiPriceHelper(qiTokenContracts[_erc20Contract], _underlyingDec, _qiTokenDec);

        trancheParameters[tranchePairsCounter].redemptionPercentage = 10000;  //default value 99.9%

        calcRPBFromPercentage(tranchePairsCounter); // initialize tranche A RPB

        emit TrancheAddedToProtocol(tranchePairsCounter, trancheAddresses[tranchePairsCounter].ATrancheAddress, trancheAddresses[tranchePairsCounter].BTrancheAddress);

        tranchePairsCounter = tranchePairsCounter.add(1);
    } 

    /**
     * @dev enables or disables tranche deposit (default: disabled)
     * @param _trancheNum tranche number
     * @param _enable true or false
     */
    function setTrancheDeposit(uint256 _trancheNum, bool _enable) external onlyAdmins {
        trancheDepositEnabled[_trancheNum] = _enable;
    }

    /**
     * @dev send an amount of tokens to corresponding compound contract (it takes tokens from this contract). Only allowed token should be sent
     * @param _erc20Contract token contract address
     * @param _numTokensToSupply token amount to be sent
     * @return mint result
     */
    function sendErc20ToCompound(address _erc20Contract, uint256 _numTokensToSupply) internal returns(uint256) {
        address qiTokenAddress = qiTokenContracts[_erc20Contract];
        require(qiTokenAddress != address(0), "!Accept");

        IERC20Upgradeable underlying = IERC20Upgradeable(_erc20Contract);

        IQiErc20 qiToken = IQiErc20(qiTokenAddress);

        SafeERC20Upgradeable.safeApprove(underlying, qiTokenAddress, _numTokensToSupply);
        require(underlying.allowance(address(this), qiTokenAddress) >= _numTokensToSupply, "!AllowQiToken");

        uint256 mintResult = qiToken.mint(_numTokensToSupply);
        return mintResult;
    }

    /**
     * @dev redeem an amount of qiTokens to have back original tokens (tokens remains in this contract). Only allowed token should be sent
     * @param _erc20Contract original token contract address
     * @param _amount qiToken amount to be sent
     * @param _redeemType true or false, normally true
     */
    function redeemQiErc20Tokens(address _erc20Contract, uint256 _amount, bool _redeemType) internal returns (uint256 redeemResult) {
        address qiTokenAddress = qiTokenContracts[_erc20Contract];
        require(qiTokenAddress != address(0),  "!Accept");

        IQiErc20 qiToken = IQiErc20(qiTokenAddress);

        if (_redeemType) {
            // Retrieve your asset based on a qiToken amount
            redeemResult = qiToken.redeem(_amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = qiToken.redeemUnderlying(_amount);
        }
        return redeemResult;
    }

    /**
     * @dev get Tranche A exchange rate
     * @param _trancheNum tranche number
     * @return tranche A token stored price
     */
    function getTrancheAExchangeRate(uint256 _trancheNum) public view override returns (uint256) {
        return trancheParameters[_trancheNum].storedTrancheAPrice;
    }

    /**
     * @dev get RPB for a given percentage (expressed in 1e18)
     * @param _trancheNum tranche number
     * @return RPB for a fixed percentage
     */
    function getTrancheACurrentRPB(uint256 _trancheNum) external view override returns (uint256) {
        return trancheParameters[_trancheNum].trancheACurrentRPB;
    }

    /**
     * @dev set Tranche A exchange rate
     * @param _trancheNum tranche number
     * @return tranche A token stored price
     */
    function setTrancheAExchangeRate(uint256 _trancheNum) internal returns (uint256) {
        calcRPBFromPercentage(_trancheNum);
        // uint256 deltaBlocks = (block.number).sub(trancheParameters[_trancheNum].trancheALastActionBlock);
        uint256 deltaTime = (block.timestamp).sub(trancheParameters[_trancheNum].trancheALastActionBlock);
        if (deltaTime > 0) {
            // uint256 deltaPrice = (trancheParameters[_trancheNum].trancheACurrentRPB).mul(deltaBlocks);
            uint256 deltaPrice = (trancheParameters[_trancheNum].trancheACurrentRPB).mul(deltaTime);
            trancheParameters[_trancheNum].storedTrancheAPrice = (trancheParameters[_trancheNum].storedTrancheAPrice).add(deltaPrice);
            // trancheParameters[_trancheNum].trancheALastActionBlock = block.number;
            trancheParameters[_trancheNum].trancheALastActionBlock = block.timestamp;
        }
        return trancheParameters[_trancheNum].storedTrancheAPrice;
    }

    /**
     * @dev get Tranche A exchange rate (tokens with 18 decimals)
     * @param _trancheNum tranche number
     * @return tranche A token current price
     */
    function calcRPBFromPercentage(uint256 _trancheNum) public returns (uint256) {
        // if normalized price in tranche A price, everything should be scaled to 1e18 
        trancheParameters[_trancheNum].trancheACurrentRPB = trancheParameters[_trancheNum].storedTrancheAPrice
            .mul(trancheParameters[_trancheNum].trancheAFixedPercentage).div(totalBlocksPerYear).div(1e18);
        return trancheParameters[_trancheNum].trancheACurrentRPB;
    }

    /**
     * @dev get Tranche A value in underlying tokens
     * @param _trancheNum tranche number
     * @return trANormValue tranche A value in underlying tokens
     */
    function getTrAValue(uint256 _trancheNum) public view override returns (uint256 trANormValue) {
        uint256 totASupply = IERC20Upgradeable(trancheAddresses[_trancheNum].ATrancheAddress).totalSupply();
        uint256 diffDec = uint256(18).sub(uint256(trancheParameters[_trancheNum].underlyingDecimals));
        uint256 storedAPrice = trancheParameters[_trancheNum].storedTrancheAPrice;
        trANormValue = totASupply.mul(storedAPrice).div(1e18).div(10 ** diffDec);
        return trANormValue;
    }

    /**
     * @dev get Tranche B value in underlying tokens
     * @param _trancheNum tranche number
     * @return tranche B valuein underlying tokens
     */
    function getTrBValue(uint256 _trancheNum) external view override returns (uint256) {
        uint256 totProtValue = getTotalValue(_trancheNum);
        uint256 totTrAValue = getTrAValue(_trancheNum);
        if (totProtValue > totTrAValue) {
            return totProtValue.sub(totTrAValue);
        } else
            return 0;
    }

    /**
     * @dev get Tranche total value in underlying tokens
     * @param _trancheNum tranche number
     * @return tranche total value in underlying tokens
     */
    function getTotalValue(uint256 _trancheNum) public view override returns (uint256) {
        address qiTokenAddress = trancheAddresses[_trancheNum].qiTokenAddress;
        uint256 underDecs = uint256(trancheParameters[_trancheNum].underlyingDecimals);
        uint256 qiTokenDecs = uint256(trancheParameters[_trancheNum].qiTokenDecimals);
        uint256 compNormPrice = IJBenQiHelper(jBenQiHelperAddress).getBenQiPriceHelper(qiTokenAddress, underDecs, qiTokenDecs);
        uint256 mantissa = IJBenQiHelper(jBenQiHelperAddress).getMantissaHelper(underDecs, qiTokenDecs);
        if (mantissa < 18) {
            compNormPrice = compNormPrice.div(10 ** (uint256(18).sub(mantissa)));
        } else {
            compNormPrice = IJBenQiHelper(jBenQiHelperAddress).getBenQiPurePriceHelper(qiTokenAddress);
        }
        uint256 totProtSupply = getTokenBalance(trancheAddresses[_trancheNum].qiTokenAddress);
        return totProtSupply.mul(compNormPrice).div(1e18);
    }

    /**
     * @dev get Tranche B exchange rate
     * @param _trancheNum tranche number
     * @param _newAmount new amount entering tranche B (in underlying tokens)
     * @return tbPrice tranche B token current price
     */
    function getTrancheBExchangeRate(uint256 _trancheNum, uint256 _newAmount) public view override returns (uint256 tbPrice) {
        // set amount of tokens to be minted via taToken price
        // Current tbDai price = (((cDai X cPrice)-(aSupply X taPrice)) / bSupply)
        // where: cDai = How much cDai we hold in the protocol
        // cPrice = cDai / Dai price
        // aSupply = Total number of taDai in protocol
        // taPrice = taDai / Dai price
        // bSupply = Total number of tbDai in protocol
        uint256 totTrBValue;

        uint256 totBSupply = IERC20Upgradeable(trancheAddresses[_trancheNum].BTrancheAddress).totalSupply(); // 18 decimals
        // if normalized price in tranche A price, everything should be scaled to 1e18 
        uint256 underlyingDec = uint256(trancheParameters[_trancheNum].underlyingDecimals);
        uint256 normAmount = _newAmount;
        if (underlyingDec < 18)
            normAmount = _newAmount.mul(10 ** uint256(18).sub(underlyingDec));
        uint256 newBSupply = totBSupply.add(normAmount); // 18 decimals

        uint256 totProtValue = getTotalValue(_trancheNum).add(_newAmount); //underlying token decimals
        uint256 totTrAValue = getTrAValue(_trancheNum); //underlying token decimals
        if (totProtValue >= totTrAValue)
            totTrBValue = totProtValue.sub(totTrAValue); //underlying token decimals
        else
            totTrBValue = 0;
        // if normalized price in tranche A price, everything should be scaled to 1e18 
        if (underlyingDec < 18 && totTrBValue > 0) {
            totTrBValue = totTrBValue.mul(10 ** (uint256(18).sub(underlyingDec)));
        }
        if (totTrBValue > 0 && newBSupply > 0) {
            // if normalized price in tranche A price, everything should be scaled to 1e18 
            tbPrice = totTrBValue.mul(1e18).div(newBSupply);
        } else
            // if normalized price in tranche A price, everything should be scaled to 1e18 
            tbPrice = uint256(1e18);

        return tbPrice;
    }

    /**
     * @dev set staking details for tranche A holders, with number, amount and time
     * @param _trancheNum tranche number
     * @param _account user's account
     * @param _stkNum staking detail counter
     * @param _amount amount of tranche A tokens
     * @param _time time to be considered the deposit
     */
    function setTrAStakingDetails(uint256 _trancheNum, address _account, uint256 _stkNum, uint256 _amount, uint256 _time) external override onlyAdmins {
        stakeCounterTrA[_account][_trancheNum] = _stkNum;
        StakingDetails storage details = stakingDetailsTrancheA[_account][_trancheNum][_stkNum];
        details.startTime = _time;
        details.amount = _amount;
    }

    /**
     * @dev when redemption occurs on tranche A, removing tranche A tokens from staking information (FIFO logic)
     * @param _trancheNum tranche number
     * @param _amount amount of redeemed tokens
     */
    function decreaseTrancheATokenFromStake(uint256 _trancheNum, uint256 _amount) internal {
        uint256 senderCounter = stakeCounterTrA[msg.sender][_trancheNum];
        uint256 tmpAmount = _amount;
        for (uint i = 1; i <= senderCounter; i++) {
            StakingDetails storage details = stakingDetailsTrancheA[msg.sender][_trancheNum][i];
            if (details.amount > 0) {
                if (details.amount <= tmpAmount) {
                    tmpAmount = tmpAmount.sub(details.amount);
                    details.amount = 0;
                } else {
                    details.amount = details.amount.sub(tmpAmount);
                    tmpAmount = 0;
                }
            }
            if (tmpAmount == 0)
                break;
        }
    }

    function getSingleTrancheUserStakeCounterTrA(address _user, uint256 _trancheNum) external view override returns (uint256) {
        return stakeCounterTrA[_user][_trancheNum];
    }

    function getSingleTrancheUserSingleStakeDetailsTrA(address _user, uint256 _trancheNum, uint256 _num) external view override returns (uint256, uint256) {
        return (stakingDetailsTrancheA[_user][_trancheNum][_num].startTime, stakingDetailsTrancheA[_user][_trancheNum][_num].amount);
    }

    /**
     * @dev set staking details for tranche B holders, with number, amount and time
     * @param _trancheNum tranche number
     * @param _account user's account
     * @param _stkNum staking detail counter
     * @param _amount amount of tranche B tokens
     * @param _time time to be considered the deposit
     */
    function setTrBStakingDetails(uint256 _trancheNum, address _account, uint256 _stkNum, uint256 _amount, uint256 _time) external override onlyAdmins {
        stakeCounterTrB[_account][_trancheNum] = _stkNum;
        StakingDetails storage details = stakingDetailsTrancheB[_account][_trancheNum][_stkNum];
        details.startTime = _time;
        details.amount = _amount; 
    }

    /**
     * @dev when redemption occurs on tranche B, removing tranche B tokens from staking information (FIFO logic)
     * @param _trancheNum tranche number
     * @param _amount amount of redeemed tokens
     */
    function decreaseTrancheBTokenFromStake(uint256 _trancheNum, uint256 _amount) internal {
        uint256 senderCounter = stakeCounterTrB[msg.sender][_trancheNum];
        uint256 tmpAmount = _amount;
        for (uint i = 1; i <= senderCounter; i++) {
            StakingDetails storage details = stakingDetailsTrancheB[msg.sender][_trancheNum][i];
            if (details.amount > 0) {
                if (details.amount <= tmpAmount) {
                    tmpAmount = tmpAmount.sub(details.amount);
                    details.amount = 0;
                    //delete stakingDetailsTrancheB[msg.sender][_trancheNum][i];
                    // update details number
                    //stakeCounterTrB[msg.sender][_trancheNum] = stakeCounterTrB[msg.sender][_trancheNum].sub(1);
                } else {
                    details.amount = details.amount.sub(tmpAmount);
                    tmpAmount = 0;
                }
            }
            if (tmpAmount == 0)
                break;
        }
    }

    function getSingleTrancheUserStakeCounterTrB(address _user, uint256 _trancheNum) external view override returns (uint256) {
        return stakeCounterTrB[_user][_trancheNum];
    }

    function getSingleTrancheUserSingleStakeDetailsTrB(address _user, uint256 _trancheNum, uint256 _num) external view override returns (uint256, uint256) {
        return (stakingDetailsTrancheB[_user][_trancheNum][_num].startTime, stakingDetailsTrancheB[_user][_trancheNum][_num].amount);
    }

    /**
     * @dev buy Tranche A Tokens
     * @param _trancheNum tranche number
     * @param _amount amount of stable coins sent by buyer
     */
    function buyTrancheAToken(uint256 _trancheNum, uint256 _amount) external payable nonReentrant {
        require(trancheDepositEnabled[_trancheNum], "!Deposit");
        address qiTokenAddress = trancheAddresses[_trancheNum].qiTokenAddress;
        address underTokenAddress = trancheAddresses[_trancheNum].buyerCoinAddress;
        uint256 prevCompTokenBalance = getTokenBalance(qiTokenAddress);
        if (underTokenAddress == address(0)){
            require(msg.value == _amount, "!Amount");
            //Transfer ETH from msg.sender to protocol;
            TransferAVAXHelper.safeTransferAVAX(address(this), _amount);
            // transfer ETH to Coompound receiving qiAvax
            qiAVAXToken.mint{value: _amount}();
        } else {
            // check approve
            require(IERC20Upgradeable(underTokenAddress).allowance(msg.sender, address(this)) >= _amount, "!Allowance");
            //Transfer DAI from msg.sender to protocol;
            SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(underTokenAddress), msg.sender, address(this), _amount);
            // transfer DAI to Coompound receiving cDai
            sendErc20ToCompound(underTokenAddress, _amount);
            // IJBenQiHelper(jBenQiHelperAddress).sendErc20ToCompoundHelper(underTokenAddress, qiTokenAddress, _amount);
        }
        uint256 newCompTokenBalance = getTokenBalance(qiTokenAddress);
        // set amount of tokens to be minted calculate taToken amount via taToken price
        setTrancheAExchangeRate(_trancheNum);
        uint256 taAmount;
        if (newCompTokenBalance > prevCompTokenBalance) {
            // if normalized price in tranche A price, everything should be scaled to 1e18 
            uint256 diffDec = uint256(18).sub(uint256(trancheParameters[_trancheNum].underlyingDecimals));
            uint256 normAmount = _amount.mul(10 ** diffDec);
            taAmount = normAmount.mul(1e18).div(trancheParameters[_trancheNum].storedTrancheAPrice);
            //Mint trancheA tokens and send them to msg.sender and notify to incentive controller BEFORE totalSupply updates
            IIncentivesController(incentivesControllerAddress).trancheANewEnter(msg.sender, trancheAddresses[_trancheNum].ATrancheAddress);
            IJTrancheTokens(trancheAddresses[_trancheNum].ATrancheAddress).mint(msg.sender, taAmount);
        } else {
            taAmount = 0;
        }

        stakeCounterTrA[msg.sender][_trancheNum] = stakeCounterTrA[msg.sender][_trancheNum].add(1);
        StakingDetails storage details = stakingDetailsTrancheA[msg.sender][_trancheNum][stakeCounterTrA[msg.sender][_trancheNum]];
        details.startTime = block.timestamp;
        details.amount = taAmount;

        lastActivity[msg.sender] = block.number;
        emit TrancheATokenMinted(_trancheNum, msg.sender, _amount, taAmount);
    }

    /**
     * @dev redeem Tranche A Tokens
     * @param _trancheNum tranche number
     * @param _amount amount of stable coins sent by buyer
     */
    function redeemTrancheAToken(uint256 _trancheNum, uint256 _amount) external nonReentrant {
        require((block.number).sub(lastActivity[msg.sender]) >= redeemTimeout, "!Timeout");
        // check approve
        // address aTrancheAddress = trancheAddresses[_trancheNum].ATrancheAddress;
        require(IERC20Upgradeable(trancheAddresses[_trancheNum].ATrancheAddress).allowance(msg.sender, address(this)) >= _amount, "!Allowance");
        //Transfer DAI from msg.sender to protocol;
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(trancheAddresses[_trancheNum].ATrancheAddress), msg.sender, address(this), _amount);

        uint256 oldBal;
        uint256 diffBal;
        uint256 userAmount;
        uint256 feesAmount;
        setTrancheAExchangeRate(_trancheNum);
        // if normalized price in tranche A price, everything should be scaled to 1e18 
        uint256 taAmount = _amount.mul(trancheParameters[_trancheNum].storedTrancheAPrice).div(1e18);
        uint256 diffDec = uint256(18).sub(uint256(trancheParameters[_trancheNum].underlyingDecimals));
        uint256 normAmount = taAmount.div(10 ** diffDec);

        address qiTokenAddress = trancheAddresses[_trancheNum].qiTokenAddress;
        uint256 qiTokenBal = getTokenBalance(qiTokenAddress); // needed for emergency
        address underTokenAddress = trancheAddresses[_trancheNum].buyerCoinAddress;
        uint256 redeemPerc = uint256(trancheParameters[_trancheNum].redemptionPercentage);
        if (underTokenAddress == address(0)) {
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(qiTokenAddress), address(avaxGateway), qiTokenBal);
            // calculate taAmount via qiAvax price
            oldBal = getEthBalance();
            avaxGateway.withdrawAVAX(normAmount, address(this), false, qiTokenBal);
            diffBal = getEthBalance().sub(oldBal);
            userAmount = diffBal.mul(redeemPerc).div(PERCENT_DIVIDER);
            TransferAVAXHelper.safeTransferAVAX(msg.sender, userAmount);
            feesAmount = diffBal.sub(userAmount);
            if (feesAmount > 0) {
                // transfer fees to JFeesCollector
                TransferAVAXHelper.safeTransferAVAX(feesCollectorAddress, feesAmount);
            }   
        } else {
            // calculate taAmount via qiToken price
            oldBal = getTokenBalance(underTokenAddress);
            uint256 retCode = redeemQiErc20Tokens(underTokenAddress, normAmount, false);
            if(retCode != 0) {
                // emergency: send all qiTokens balance to compound 
                redeemQiErc20Tokens(underTokenAddress, qiTokenBal, true); 
            }
            diffBal = getTokenBalance(underTokenAddress).sub(oldBal);
            userAmount = diffBal.mul(redeemPerc).div(PERCENT_DIVIDER);
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(underTokenAddress), msg.sender, userAmount);
            feesAmount = diffBal.sub(userAmount);
            if (feesAmount > 0) {
                // transfer fees to JFeesCollector
                SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(underTokenAddress), feesCollectorAddress, feesAmount);
            }
        }

        // claim and transfer rewards to msg.sender. Be sure to wait for this function to be completed! 
        bool rewClaimCompleted = IIncentivesController(incentivesControllerAddress).claimRewardsAllMarkets(msg.sender);

        // decrease tokens after claiming rewards
        if (rewClaimCompleted && _amount > 0)
           decreaseTrancheATokenFromStake(_trancheNum, _amount);
     
        IJTrancheTokens(trancheAddresses[_trancheNum].ATrancheAddress).burn(_amount);

        lastActivity[msg.sender] = block.number;
        emit TrancheATokenRedemption(_trancheNum, msg.sender, 0, userAmount, feesAmount);
    }

    /**
     * @dev buy Tranche B Tokens
     * @param _trancheNum tranche number
     * @param _amount amount of stable coins sent by buyer
     */
    function buyTrancheBToken(uint256 _trancheNum, uint256 _amount) external payable nonReentrant {
        require(trancheDepositEnabled[_trancheNum], "!Deposit");
        address qiTokenAddress = trancheAddresses[_trancheNum].qiTokenAddress;
        address underTokenAddress = trancheAddresses[_trancheNum].buyerCoinAddress;
        uint256 prevCompTokenBalance = getTokenBalance(qiTokenAddress);
        // if eth, ignore _amount parameter and set it to msg.value
        if (trancheAddresses[_trancheNum].buyerCoinAddress == address(0)) {
            require(msg.value == _amount, "!Amount");
            //_amount = msg.value;
        }
        // refresh value for tranche A
        setTrancheAExchangeRate(_trancheNum);
        // get tranche B exchange rate
        // if normalized price in tranche B price, everything should be scaled to 1e18 
        uint256 diffDec = uint256(18).sub(uint256(trancheParameters[_trancheNum].underlyingDecimals));
        uint256 normAmount = _amount.mul(10 ** diffDec);
        uint256 tbAmount = normAmount.mul(1e18).div(getTrancheBExchangeRate(_trancheNum, _amount));
        if (underTokenAddress == address(0)) {
            TransferAVAXHelper.safeTransferAVAX(address(this), _amount);
            // transfer ETH to Coompound receiving qiAvax
            qiAVAXToken.mint{value: _amount}();
        } else {
            // check approve
            require(IERC20Upgradeable(underTokenAddress).allowance(msg.sender, address(this)) >= _amount, "!Allowance");
            //Transfer DAI from msg.sender to protocol;
            SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(underTokenAddress), msg.sender, address(this), _amount);
            // transfer DAI to Couompound receiving cDai
            sendErc20ToCompound(underTokenAddress, _amount);
            // IJBenQiHelper(jBenQiHelperAddress).sendErc20ToCompoundHelper(underTokenAddress, qiTokenAddress, _amount);
        }
        uint256 newCompTokenBalance = getTokenBalance(qiTokenAddress);
        if (newCompTokenBalance > prevCompTokenBalance) {
            //Mint trancheB tokens and send them to msg.sender and notify to incentive controller BEFORE totalSupply updates
            IIncentivesController(incentivesControllerAddress).trancheBNewEnter(msg.sender, trancheAddresses[_trancheNum].BTrancheAddress);
            IJTrancheTokens(trancheAddresses[_trancheNum].BTrancheAddress).mint(msg.sender, tbAmount);
        } else 
            tbAmount = 0;

        stakeCounterTrB[msg.sender][_trancheNum] = stakeCounterTrB[msg.sender][_trancheNum].add(1);
        StakingDetails storage details = stakingDetailsTrancheB[msg.sender][_trancheNum][stakeCounterTrB[msg.sender][_trancheNum]];
        details.startTime = block.timestamp;
        details.amount = tbAmount;     

        lastActivity[msg.sender] = block.number;
        emit TrancheBTokenMinted(_trancheNum, msg.sender, _amount, tbAmount);
    }

    /**
     * @dev redeem Tranche B Tokens
     * @param _trancheNum tranche number
     * @param _amount amount of stable coins sent by buyer
     */
    function redeemTrancheBToken(uint256 _trancheNum, uint256 _amount) external nonReentrant {
        require((block.number).sub(lastActivity[msg.sender]) >= redeemTimeout, "!Timeout");
        // check approve
        // address bTrancheAddress = trancheAddresses[_trancheNum].BTrancheAddress;
        require(IERC20Upgradeable(trancheAddresses[_trancheNum].BTrancheAddress).allowance(msg.sender, address(this)) >= _amount, "!Allowance");
        //Transfer DAI from msg.sender to protocol;
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(trancheAddresses[_trancheNum].BTrancheAddress), msg.sender, address(this), _amount);

        uint256 oldBal;
        uint256 diffBal;
        uint256 userAmount;
        uint256 feesAmount;
        // refresh value for tranche A
        setTrancheAExchangeRate(_trancheNum);
        // get tranche B exchange rate
        // if normalized price in tranche B price, everything should be scaled to 1e18 
        uint256 tbAmount = _amount.mul(getTrancheBExchangeRate(_trancheNum, 0)).div(1e18);
        uint256 diffDec = uint256(18).sub(uint256(trancheParameters[_trancheNum].underlyingDecimals));
        uint256 normAmount = tbAmount.div(10 ** diffDec);

        address qiTokenAddress = trancheAddresses[_trancheNum].qiTokenAddress;
        uint256 qiTokenBal = getTokenBalance(qiTokenAddress); // needed for emergency
        address underTokenAddress = trancheAddresses[_trancheNum].buyerCoinAddress;
        uint256 redeemPerc = uint256(trancheParameters[_trancheNum].redemptionPercentage);
        if (underTokenAddress == address(0)){
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(qiTokenAddress), address(avaxGateway), qiTokenBal);
            // calculate tbETH amount via qiAvax price
            oldBal = getEthBalance();
            avaxGateway.withdrawAVAX(normAmount, address(this), false, qiTokenBal);
            diffBal = getEthBalance().sub(oldBal);
            userAmount = diffBal.mul(redeemPerc).div(PERCENT_DIVIDER);
            TransferAVAXHelper.safeTransferAVAX(msg.sender, userAmount);
            feesAmount = diffBal.sub(userAmount);
            if (feesAmount > 0) {
                // transfer fees to JFeesCollector
                TransferAVAXHelper.safeTransferAVAX(feesCollectorAddress, feesAmount);
            }   
        } else {
            // calculate taToken amount via qiToken price
            oldBal = getTokenBalance(underTokenAddress);
            uint256 retCode = redeemQiErc20Tokens(underTokenAddress, normAmount, false);
            if(retCode != 0) {
                // emergency: send all qiTokens balance to compound 
                redeemQiErc20Tokens(underTokenAddress, qiTokenBal, true); 
            }
            diffBal = getTokenBalance(underTokenAddress);
            userAmount = diffBal.mul(redeemPerc).div(PERCENT_DIVIDER);
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(underTokenAddress), msg.sender, userAmount);
            feesAmount = diffBal.sub(userAmount);
            if (feesAmount > 0) {
                // transfer fees to JFeesCollector
                SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(underTokenAddress), feesCollectorAddress, feesAmount);
            }   
        }

        // claim and transfer rewards to msg.sender. Be sure to wait for this function to be completed! 
        bool rewClaimCompleted = IIncentivesController(incentivesControllerAddress).claimRewardsAllMarkets(msg.sender);

        // decrease tokens after claiming rewards
        if (rewClaimCompleted && _amount > 0)
            decreaseTrancheBTokenFromStake(_trancheNum, _amount);

        IJTrancheTokens(trancheAddresses[_trancheNum].BTrancheAddress).burn(_amount);

        lastActivity[msg.sender] = block.number;
        emit TrancheBTokenRedemption(_trancheNum, msg.sender, 0, userAmount, feesAmount);
    }

    /**
     * @dev redeem every qiToken amount and send values to fees collector
     * @param _trancheNum tranche number
     * @param _qiTokenAmount qiToken amount to send to compound protocol
     */
    function redeemQiTokenAmount(uint256 _trancheNum, uint256 _qiTokenAmount) external onlyAdmins nonReentrant {
        uint256 oldBal;
        uint256 diffBal;
        address underTokenAddress = trancheAddresses[_trancheNum].buyerCoinAddress;
        uint256 qiTokenBal = getTokenBalance(trancheAddresses[_trancheNum].qiTokenAddress); // needed for emergency
        if (underTokenAddress == address(0)) {
            oldBal = getEthBalance();
            avaxGateway.withdrawAVAX(_qiTokenAmount, address(this), true, qiTokenBal);
            diffBal = getEthBalance().sub(oldBal);
            TransferAVAXHelper.safeTransferAVAX(feesCollectorAddress, diffBal);
        } else {
            // calculate taToken amount via qiToken price
            oldBal = getTokenBalance(underTokenAddress);
            require(redeemQiErc20Tokens(underTokenAddress, _qiTokenAmount, true) == 0, "!qiTokenAnswer");
            // address qiToken = qiTokenContracts[trancheAddresses[_trancheNum].buyerCoinAddress];
            // uint256 compRetCode = IJBenQiHelper(jBenQiHelperAddress).redeemQiErc20TokensHelper(qiToken, _qiTokenAmount, false);
            // require(compRetCode == 0, "!qiTokenAnswer");
            diffBal = getTokenBalance(underTokenAddress);
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(underTokenAddress), feesCollectorAddress, diffBal);
        }
    }

    /**
     * @dev get every token balance in this contract
     * @param _tokenContract token contract address
     */
    function getTokenBalance(address _tokenContract) public view returns (uint256) {
        return IERC20Upgradeable(_tokenContract).balanceOf(address(this));
    }

    /**
     * @dev get eth balance on this contract
     */
    function getEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev transfer tokens in this contract to fees collector contract
     * @param _tokenContract token contract address
     * @param _amount token amount to be transferred 
     */
    function transferTokenToFeesCollector(address _tokenContract, uint256 _amount) external onlyAdmins {
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_tokenContract), feesCollectorAddress, _amount);
    }

    /**
     * @dev transfer ethers in this contract to fees collector contract
     * @param _amount ethers amount to be transferred 
     */
    function withdrawAVAXToFeesCollector(uint256 _amount) external onlyAdmins {
        TransferAVAXHelper.safeTransferAVAX(feesCollectorAddress, _amount);
    }

    /**
     * @dev get total accrued Comp token from all market in comptroller
     * @return comp amount accrued
     */
    function getTotalQiAccrued() public view onlyAdmins returns (uint256) {
        return IComptrollerLensInterface(trollerAddress).compAccrued(address(this));
    }

    /**
     * @dev claim total accrued Comp token from all market in comptroller and transfer the amount to a receiver address
     * @param _receiver destination address
     */
    function claimTotalQiAccruedToReceiver(address _receiver) external onlyAdmins nonReentrant {
        uint256 totAccruedAmount = getTotalQiAccrued();
        if (totAccruedAmount > 0) {
            IComptrollerLensInterface(trollerAddress).claimComp(address(this));
            uint256 amount = IERC20Upgradeable(qiTokenAddress).balanceOf(address(this));
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(qiTokenAddress), _receiver, amount);
        }
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
library SafeMathUpgradeable {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQiErc20 {
    function mint(uint256) external returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function supplyRatePerBlock() external view returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function setExchangeRateStored(uint256 rate) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQiAvax {
    function mint() external payable;
    function exchangeRateCurrent() external returns (uint256);
    function supplyRatePerBlock() external view returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function setExchangeRateStored(uint256 rate) external;
}

// SPDX-License-Identifier: MIT
/**
 * Created on 2021-01-15
 * @summary: JProtocol Interface
 * @author: Jibrel Team
 */
pragma solidity ^0.8.0;

interface IJTranchesDeployer {
    function deployNewTrancheATokens(string memory _nameA, string memory _symbolA, uint256 _trNum) external returns (address);
    function deployNewTrancheBTokens(string memory _nameB, string memory _symbolB, uint256 _trNum) external returns (address);
}

// SPDX-License-Identifier: MIT
/**
 * Created on 2021-01-16
 * @summary: JTranches Interface
 * @author: Jibrel Team
 */
pragma solidity 0.8.8;

interface IJTrancheTokens {
    function mint(address account, uint256 value) external;
    function burn(uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBenQiHelper {
    // function sendErc20ToCompoundHelper(address _underToken, address _cToken, uint256 _numTokensToSupply) external returns(uint256);
    // function redeemQiErc20TokensHelper(address _cToken, uint256 _amount, bool _redeemType) external returns (uint256 redeemResult);

    function getMantissaHelper(uint256 _underDecs, uint256 _cTokenDecs) external pure returns (uint256 mantissa);
    function getBenQiPurePriceHelper(address _cTokenAddress) external view returns (uint256 compoundPrice);
    function getBenQiPriceHelper(address _cTokenAddress, uint256 _underDecs, uint256 _cTokenDecs) external view returns (uint256 compNormPrice);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBenQi {
    event TrancheAddedToProtocol(uint256 trancheNum, address trancheA, address trancheB);
    event TrancheATokenMinted(uint256 trancheNum, address buyer, uint256 amount, uint256 taAmount);
    event TrancheBTokenMinted(uint256 trancheNum, address buyer, uint256 amount, uint256 tbAmount);
    event TrancheATokenRedemption(uint256 trancheNum, address burner, uint256 amount, uint256 userAmount, uint256 feesAmount);
    event TrancheBTokenRedemption(uint256 trancheNum, address burner, uint256 amount, uint256 userAmount, uint256 feesAmount);

    function getSingleTrancheUserStakeCounterTrA(address _user, uint256 _trancheNum) external view returns (uint256);
    function getSingleTrancheUserStakeCounterTrB(address _user, uint256 _trancheNum) external view returns (uint256);
    function getSingleTrancheUserSingleStakeDetailsTrA(address _user, uint256 _trancheNum, uint256 _num) external view returns (uint256, uint256);
    function getSingleTrancheUserSingleStakeDetailsTrB(address _user, uint256 _trancheNum, uint256 _num) external view returns (uint256, uint256);
    function getTrAValue(uint256 _trancheNum) external view returns (uint256 trANormValue);
    function getTrBValue(uint256 _trancheNum) external view returns (uint256);
    function getTotalValue(uint256 _trancheNum) external view returns (uint256);
    function getTrancheACurrentRPB(uint256 _trancheNum) external view returns (uint256);
    function getTrancheAExchangeRate(uint256 _trancheNum) external view returns (uint256);
    function getTrancheBExchangeRate(uint256 _trancheNum, uint256 _newAmount) external view returns (uint256 tbPrice);
    function getIncentivesControllerAddress() external view returns (address);
    function setIncentivesControllerAddress(address _incentivesController) external;
    function setTrAStakingDetails(uint256 _trancheNum, address _account, uint256 _stkNum, uint256 _amount, uint256 _time) external;
    function setTrBStakingDetails(uint256 _trancheNum, address _account, uint256 _stkNum, uint256 _amount, uint256 _time) external;
}

// SPDX-License-Identifier: MIT
/**
 * Created on 2021-05-16
 * @summary: Admin Tools Interface
 * @author: Jibrel Team
 */
pragma solidity ^0.8.0;

interface IJAdminTools {
    function isAdmin(address account) external view returns (bool);
    function addAdmin(address account) external;
    function removeAdmin(address account) external;
    function renounceAdmin() external;

    event AdminAdded(address account);
    event AdminRemoved(address account);
}

// SPDX-License-Identifier: MIT
/**
 * Created on 2021-06-18
 * @summary: Markets Interface
 * @author: Jibrel Team
 */
pragma solidity 0.8.8;

interface IIncentivesController {
    function trancheANewEnter(address account, address trancheA) external;
    function trancheBNewEnter(address account, address trancheA) external;

    function claimRewardsAllMarkets(address _account) external returns (bool);
    function claimRewardSingleMarketTrA(uint256 _idxMarket, uint256 _distCount, address _account) external;
    function claimRewardSingleMarketTrB(uint256 _idxMarket, uint256 _distCount, address _account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IComptrollerLensInterface {
    function claimComp(address) external;
    function compAccrued(address) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAVAXGateway {
  function withdrawAVAX(uint256 amount, address onBehalfOf, bool redeemType, uint256 _cEthBal) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferAVAXHelper {
    function safeTransferAVAX(address _to, uint256 _value) internal {
        (bool success,) = _to.call{value:_value}(new bytes(0));
        require(success, 'TH AVAX_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
/**
 * Created on 2021-01-16
 * @summary: Jibrel Protocol Storage
 * @author: Jibrel Team
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IQiAvax.sol";
import "./interfaces/IAVAXGateway.sol";

contract JBenQiStorage is OwnableUpgradeable {
/* WARNING: NEVER RE-ORDER VARIABLES! Always double-check that new variables are added APPEND-ONLY. Re-ordering variables can permanently BREAK the deployed proxy contract.*/

    uint256 public constant PERCENT_DIVIDER = 10000;  // percentage divider for redemption

    struct TrancheAddresses {
        address buyerCoinAddress;       // ETH (ZERO_ADDRESS) or DAI
        address qiTokenAddress;          // qiAVAX or cDAI
        address ATrancheAddress;
        address BTrancheAddress;
    }

    struct TrancheParameters {
        uint256 trancheAFixedPercentage;    // fixed percentage (i.e. 4% = 0.04 * 10^18 = 40000000000000000)
        uint256 trancheALastActionBlock;
        uint256 storedTrancheAPrice;
        uint256 trancheACurrentRPB;
        uint16 redemptionPercentage;        // percentage with 2 decimals (divided by 10000, i.e. 95% is 9500)
        uint8 qiTokenDecimals;
        uint8 underlyingDecimals;
    }

    address public adminToolsAddress;
    address public feesCollectorAddress;
    address public tranchesDeployerAddress;
    address public qiTokenAddress;
    address public trollerAddress;
    address public rewardsToken;

    uint256 public tranchePairsCounter;
    uint256 public totalBlocksPerYear; 
    uint32 public redeemTimeout;

    mapping(address => address) public qiTokenContracts;
    mapping(uint256 => TrancheAddresses) public trancheAddresses;
    mapping(uint256 => TrancheParameters) public trancheParameters;
    // last block number when the user buy/reddem tranche tokens
    mapping(address => uint256) public lastActivity;

    IQiAvax public qiAVAXToken;
    IAVAXGateway public avaxGateway;

    // enabling / disabling tranches for fund deposit
    mapping(uint256 => bool) public trancheDepositEnabled;
}


contract JBenQiStorageV2 is JBenQiStorage {
    struct StakingDetails {
        uint256 startTime;
        uint256 amount;
    }

    address public incentivesControllerAddress;

    // user => trancheNum => counter
    mapping (address => mapping(uint256 => uint256)) public stakeCounterTrA;
    mapping (address => mapping(uint256 => uint256)) public stakeCounterTrB;
    // user => trancheNum => stakeCounter => struct
    mapping (address => mapping (uint256 => mapping (uint256 => StakingDetails))) public stakingDetailsTrancheA;
    mapping (address => mapping (uint256 => mapping (uint256 => StakingDetails))) public stakingDetailsTrancheB;

    address public jBenQiHelperAddress;
}