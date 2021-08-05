pragma solidity ^0.6.4;

import "SafeMath.sol";
import "EIP20Interface.sol";
import "AucReceiverInterface.sol";
import "UniswapFactoryInterface.sol";
import "DPiggyInterface.sol";
import "DPiggyAssetInterface.sol";
import "DPiggyBaseProxyInterface.sol";
import "DPiggyAssetProxy.sol";
import "DPiggyData.sol";

/**
 * @title DPiggy
 * @dev The contract is proxied for dPiggyProxy.
 * It is the implementation of the gateway contract for dPiggy.
 * The contract manages all assets and general data for dPiggy system.
 */
contract DPiggy is DPiggyData, DPiggyInterface, AucReceiverInterface {
    using SafeMath for uint256;

    /**
     * @dev Function to initialize the contract.
     * It should be called through the `data` argument when creating the proxy.
     * It must be called only once. The `assert` is to guarantee that behavior.
     * @param _percentagePrecision The percentage precision. The value represents the 100%.
     * @param _dailyFee The daily fee percentage (with percentage precision).
     * @param _maximumDailyFee The maximum value that can be defined for the daily fee percentage.
     * @param _minimumAucToFreeFee The minimum amount of Auc escrowed to have the fee exemption.
     * @param _dai Address for the Dai token contract.
     * @param _compound Address for the cDai (the Compound contract).
     * @param _uniswapFactory Address for the Uniswap factory contract.
     * @param _auc Address for the Auc token contract.
     * @param _assetImplementation Address for the asset base implementation contract.
     */
    function init(
        uint256 _percentagePrecision,
        uint256 _dailyFee,
        uint256 _maximumDailyFee,
        uint256 _minimumAucToFreeFee,
        address _dai,
        address _compound,
        address _uniswapFactory,
        address _auc,
        address _assetImplementation) public {
        
        assert(
            assetImplementation == address(0) && 
            auc == address(0) && 
            dai == address(0) && 
            percentagePrecision == 0 && 
            maximumDailyFee == 0
        );
        
        require(_dailyFee <= _maximumDailyFee, "DPiggy::init: Invalid fee");
        
        percentagePrecision = _percentagePrecision;
        dailyFee = _dailyFee;
        maximumDailyFee = _maximumDailyFee;
        minimumAucToFreeFee = _minimumAucToFreeFee;
        dai = _dai;
        auc = _auc;
        compound = _compound;
        assetImplementation = _assetImplementation;
        uniswapFactory = _uniswapFactory;
        
        //Set Dai Uniswap exchange using the uniswapFactory address.
        setExchange();
        
        /* Initialize the stored data that controls the reentrancy guard.
         * Due to the proxy, it must be set on a separate initialize method instead of the constructor.
         */
        _notEntered = true;
    }
    
    /**
     * @dev Function to guarantee that the contract will not receive ether.
     */
    receive() external payable {
        revert();
    }
    
    /**
     * @dev Function to calculate the Compound redeem fee.
     * It calculates how many days the argument represents then it is calculated:
     * (100% + `dailyFee`)^(number of days) - 100%
     * @param baseTime Period of time in seconds. It is not a Unix time.
     * @return Fee for the amount of time informed with a dPiggy percentage precision.
     */
    function executionFee(uint256 baseTime) external override(DPiggyInterface) view returns(uint256) {
        uint256 daysAmount = baseTime / 86400;
        if (daysAmount == 0) {
            return 0;
        } else {
            uint256 pow = percentagePrecision + dailyFee;
            uint256 base = pow;
            for (uint256 i = 1; i < daysAmount; ++i) {
                pow = (base * pow / percentagePrecision);
            }
            return pow - percentagePrecision;
        }
    }
    
    /**
     * @dev Function to return the escrow start time.
     * @param user User's address.
     * @return The Unix time for user escrow start. Zero means no escrow.
     */
    function escrowStart(address user) external override(DPiggyInterface) view returns(uint256) {
        EscrowData storage escrow = usersEscrow[user];
        return escrow.time;
    }
    
    /**
     * @dev Forwarding function to dPiggy asset to get the total amount of Dai deposited.
     * @param tokenAddress The ERC20 token address on the chain or '0x0' for Ethereum. 
     * @return The total amount of Dai deposited.
     */
    function getTotalInvested(address tokenAddress) external view returns(uint256) {
        return _getValueFromAsset(tokenAddress, abi.encodeWithSignature("totalBalance()"));
    }
    
    /**
     * @dev Forwarding function to dPiggy asset to get the minimum time for the next Compound redeem execution.
     * @param tokenAddress The ERC20 token address on the chain or '0x0' for Ethereum. 
     * @return The minimum time in Unix for the next Compound redeem execution.
     */
    function getMinimumTimeForNextExecution(address tokenAddress) external view returns(uint256) {
        return _getValueFromAsset(tokenAddress, abi.encodeWithSignature("getMinimumTimeForNextExecution()"));
    }
    
    /**
     * @dev Function to get the minimum amount of Dai allowed to deposit on the asset.
     * @param tokenAddress The ERC20 token address on the chain or '0x0' for Ethereum. 
     * @return The minimum amount of Dai allowed to deposit on the asset.
     */
    function getMinimumDeposit(address tokenAddress) external view returns(uint256) {
        AssetData storage assetData = assetsData[tokenAddress];
        if (assetData.time > 0) {
            return assetData.minimumDeposit;
        }
        return 0;
    }
    
    /**
     * @dev Forwarding function to dPiggy asset to get the user's Dai gross profit, asset net profit and the fee amount in Dai.
     * @param tokenAddress The ERC20 token address on the chain or '0x0' for Ethereum. 
     * @param user User's address. 
     * @return The user's Dai gross profit, asset net profit and the fee amount charged in Dai. 
     * First return is the gross profit in Dai.
     * Second return is the asset net profit.
     * Third return is the fee amount charged in Dai.
     */
    function getUserProfitsAndFeeAmount(address tokenAddress, address user) external view returns(uint256, uint256, uint256) {
        AssetData storage assetData = assetsData[tokenAddress];
        if (assetData.time > 0) {
            return DPiggyAssetInterface(assetData.proxy).getUserProfitsAndFeeAmount(user);
        }
        return (0, 0, 0);
    }
    
    /**
     * @dev Forwarding function to dPiggy asset to get the estimated current gross profit in Dai for the user.
     * So it is not the total gross profit, it is only for the user amount of Dai on the next Compound redeem execution.
     * The estimative to the amount of Dai on the Compound redeem execution considering the Compound exchange rate now.
     * For an estimated total of the gross profit: `getUserProfit` + `getUserEstimatedCurrentProfitWithoutFee`.
     * @param tokenAddress The ERC20 token address on the chain or '0x0' for Ethereum. 
     * @param user User's address. 
     * @return The estimated gross profit in Dai. 
     */
    function getUserEstimatedCurrentProfitWithoutFee(address tokenAddress, address user) external view returns(uint256) {
        return _getValueFromAsset(tokenAddress, abi.encodeWithSignature("getUserEstimatedCurrentProfitWithoutFee(address)", user));
    }
    
    /**
     * @dev Forwarding function to dPiggy asset to get the estimated current fee in Dai for the user.
     * To estimate the amount of fee on the Compound redeem execution, it is calculated by the difference between the `time` and the last execution time.
     * So it is not the total amount of fee, for an estimated total of the fee in Dai: 
     * `getUserAssetProfitAndFeeAmount(second return)` + `getUserEstimatedCurrentFee`.
     * @param tokenAddress The ERC20 token address on the chain or '0x0' for Ethereum. 
     * @param user User's address. 
     * @param time The Unix time to calculate the fee. It should be the current Unix time. 
     * @return The estimated fee in Dai. 
     */
    function getUserEstimatedCurrentFee(address tokenAddress, address user, uint256 time) external view returns(uint256) {
        return _getValueFromAsset(tokenAddress, abi.encodeWithSignature("getUserEstimatedCurrentFee(address,uint256)", user, time));
    }
    
    /**
     * @dev Forwarding function to dPiggy asset to get the amount of asset redeemed for the user.
     * @param tokenAddress The ERC20 token address on the chain or '0x0' for Ethereum. 
     * @param user User's address. 
     * @return The amount of asset redeemed. 
     */
    function getUserAssetRedeemed(address tokenAddress, address user) external view returns(uint256) {
        return _getValueFromAsset(tokenAddress, abi.encodeWithSignature("getUserAssetRedeemed(address)", user));
    }
    
    /**
     * @dev Forwarding function to dPiggy asset to get the amount of Dai deposited for the user.
     * @param tokenAddress The ERC20 token address on the chain or '0x0' for Ethereum. 
     * @param user User's address. 
     * @return The amount of Dai deposited. 
     */
    function getUserTotalInvested(address tokenAddress, address user) external view returns(uint256) {
        return _getValueFromAsset(tokenAddress, abi.encodeWithSignature("getUserTotalInvested(address)", user));
    }
    
    /**
     * @dev Function to set Dai Uniswap exchange using the uniswapFactory address.
     * It is public because uses fixed and controlled parameters.
     */
    function setExchange() public {
        exchange = UniswapFactoryInterface(uniswapFactory).getExchange(dai);  
    }
    
    /**
     * @dev Function to set the daily fee.
     * Only can be called by the admin.
     * The new value must be lower than the stored maximum daily fee.
     * @param _dailyFee New daily fee with dPiggy percentage precision.
     */
    function setDailyFee(uint256 _dailyFee) onlyAdmin external {
        require(_dailyFee <= maximumDailyFee, "DPiggy::setDailyFee: Invalid fee");
        uint256 oldDailyFee = dailyFee;
        dailyFee = _dailyFee;
        emit SetDailyFee(_dailyFee, oldDailyFee);
    }
    
    /**
     * @dev Function to set the minimum amount of Auc escrowed to have the fee exemption.
     * Only can be called by the admin.
     * @param _minimumAucToFreeFee New minimum amount of Auc.
     */
    function setMinimumAucToFreeFee(uint256 _minimumAucToFreeFee) onlyAdmin external {
        uint256 oldMinimumAucToFreeFee = minimumAucToFreeFee;
        minimumAucToFreeFee = _minimumAucToFreeFee;
        emit SetMinimumAucToFreeFee(_minimumAucToFreeFee, oldMinimumAucToFreeFee);
    }
    
    /**
     * @dev Function to set the implementation address for the dPiggy assets proxy.
     * Only can be called by the admin.
     * @param _assetImplementation New implementation contract address.
     * @param updateData (optional) ABI encoded with signature data that will be delegated on the new implementation.
     */
    function setAssetImplementation(address _assetImplementation, bytes calldata updateData) onlyAdmin external payable {
        for (uint256 i = 0; i < assets.length; i++) {
            AssetData storage assetData = assetsData[assets[i]];
            DPiggyBaseProxyInterface(assetData.proxy).setImplementation(_assetImplementation, updateData);
        }
        
        assetImplementation = _assetImplementation;
    }
    
    /**
     * @dev Function to set the new proxy for the dPiggy asset and migrates the previous data.
     * Only can be called by the admin.
     * @param tokenAddress The ERC20 token address on the chain or '0x0' for Ethereum. 
     * @param _assetImplementation New implementation contract address.
     * @param users The users to copy their stored data.
     */
    function migrateAssetProxy(address tokenAddress, address _assetImplementation, address[] calldata users) onlyAdmin external {
        AssetData storage assetData = assetsData[tokenAddress];
        require(assetData.time > 0, "DPiggy::migrateAssetProxy: Invalid tokenAddress");
        
        // Encoded data to initialize the new proxy with the previous asset data.
        bytes memory initData = abi.encodeWithSignature("initMigratingData(address,address[])", assetData.proxy, users);    
        address newProxy = address(new DPiggyAssetProxy(address(this), _assetImplementation, initData));
        
        // Encoded data to resign the previous implementation of the asset.
        bytes memory resignData = abi.encodeWithSignature("resignAssetForMigration(address[])", users);
        // Resign the implementation and get the cDai and asset amount.
        (bool success, bytes memory returnData) = assetData.proxy.call(resignData);
        assert(success);
        uint256[] memory amounts = _getUint256(returnData);
        
        // Transfer the amounts for the new proxy contract.
        if (amounts[0] > 0) {
            assert(EIP20Interface(compound).transfer(newProxy, amounts[0]));
        }
        if (amounts[1] > 0) {
            if (tokenAddress != address(0)) {
                assert(EIP20Interface(tokenAddress).transfer(newProxy, amounts[1]));
            } else {
                Address.toPayable(newProxy).transfer(amounts[1]);
            }
        }
        
        // Update the asset proxy address.
        assetData.proxy = newProxy;
    }
    
    /**
     * @dev Function to create a new dPiggy asset.
     * Only can be called by the admin.
     * The asset cannot already exist on dPiggy.
     * A DPiggyAssetProxy is created using the `assetImplementation` address.
     * dPiggy contract is the admin for this proxy.
     * @param tokenAddress The ERC20 token address on the chain or '0x0' for Ethereum. 
     * @param minimumDeposit The minimum amount of Dai that can be deposited for the asset.
     * @param creationData ABI encoded with signature data that will be delegated on the new implementation.
     */
    function createAsset(
        address tokenAddress, 
        uint256 minimumDeposit,
        bytes calldata creationData
    ) onlyAdmin external payable {     
        
        AssetData storage assetData = assetsData[tokenAddress];
        require(assetData.time == 0, "DPiggy::createAsset: Asset already exists");
        assetData.time = now;
        assetData.depositAllowed = false;
        assetData.minimumDeposit = minimumDeposit;
        assetData.proxy = address(new DPiggyAssetProxy(address(this), assetImplementation, creationData));
        
        assets.push(tokenAddress);
        numberOfAssets++;
        
        emit SetNewAsset(tokenAddress, assetData.proxy); 
    }
    
    /**
     * @dev Function to set the deposit permission for dPiggy asset.
     * Only can be called by the admin.
     * Both array parameters must be the same size because the value is set through the same array index position.
     * @param tokenAddresses Array with ERC20 token addresses or '0x0' for Ethereum. The asset must already exist on dPiggy.
     * @param allowed Array with the deposit permission conditions.
     */
    function setAssetsDepositAllowed(address[] calldata tokenAddresses, bool[] calldata allowed) onlyAdmin external {
        require(tokenAddresses.length > 0, "DPiggy::setAssetsDepositAllowed: tokenAddresses is required");
        require(tokenAddresses.length == allowed.length, "DPiggy::setAssetsDepositAllowed: Invalid data");
        
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            AssetData storage assetData = assetsData[tokenAddresses[i]];
            if (assetData.time > 0) {
                bool oldDepositAllowed = assetData.depositAllowed;
                assetData.depositAllowed = allowed[i];
                emit SetAssetDepositAllowed(tokenAddresses[i], allowed[i], oldDepositAllowed);
            }
        }   
    }
    
    /**
     * @dev Function to set the minimum amount of Dai allowed to deposit on dPiggy asset.
     * Only can be called by the admin.
     * Both array parameters must be the same size because the value is set through the same array index position.
     * @param tokenAddresses Array with ERC20 token addresses or '0x0' for Ethereum. The asset must already exist on dPiggy.
     * @param minimumDeposits Array with the minimum amount of Dai allowed for deposit.
     */
    function setAssetsMinimumDeposit(address[] calldata tokenAddresses, uint256[] calldata minimumDeposits) onlyAdmin external {
        require(tokenAddresses.length > 0, "DPiggy::setAssetsMinimumDeposit: tokenAddresses is required");
        require(tokenAddresses.length == minimumDeposits.length, "DPiggy::setAssetsMinimumDeposit: Invalid data");
        
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            AssetData storage assetData = assetsData[tokenAddresses[i]];
            if (assetData.time > 0) {
                uint256 oldMinimumDeposit = assetData.minimumDeposit;
                assetData.minimumDeposit = minimumDeposits[i];
                emit SetAssetMinimumDeposit(tokenAddresses[i], minimumDeposits[i], oldMinimumDeposit);
            }
        }
    }
    
    /**
     * @dev Forwarding function to dPiggy asset to set the minimum time between the Compound redeem executions for a dPiggy asset.
     * Only can be called by the admin.
     * @param tokenAddress The ERC20 token address on the chain or '0x0' for Ethereum. The asset must already exist on dPiggy.
     * @param time New minimum time in seconds between the Compound redeem executions.
     */
    function setMinimumTimeBetweenExecutions(address tokenAddress, uint256 time) onlyAdmin external {
        AssetData storage assetData = assetsData[tokenAddress];
        require(assetData.time > 0, "DPiggy::setMinimumTimeBetweenExecutions: Invalid tokenAddress");
        DPiggyAssetInterface(assetData.proxy).setMinimumTimeBetweenExecutions(time);  
    }
    
    /**
     * @dev Forwarding function to dPiggy asset to deliberately redeem the user asset profit.
     * Only can be called by the admin.
     * Although being called by the admin, the user asset profit is redeemed to the respective user address. 
     * @param users Array with user addresses.
     * @param tokenAddresses Array with ERC20 token addresses or '0x0' for Ethereum. The asset must already exist on dPiggy.
     */
    function forceRedeem(address[] calldata users, address[] calldata tokenAddresses) nonReentrant onlyAdmin external {
        require(users.length > 0, "DPiggy::forceRedeem: users is required");
        
        for (uint256 i = 0; i < users.length; i++) {
            _setAsset(tokenAddresses, abi.encodeWithSignature("forceRedeem(address)", users[i]));
        }
    }
    
    /**
     * @dev Forwarding function to dPiggy asset to deliberately finish the user participation.
     * All asset profit is redeemed as well as all the Dai deposited for the respective assets. 
     * Only can be called by the admin.
     * Although being called by the admin, assets and Dai redeemed are done to the respective user address. 
     * @param users Array with user addresses.
     * @param tokenAddresses Array with ERC20 token addresses or '0x0' for Ethereum. The asset must already exist on dPiggy.
     */
    function forceFinish(address[] calldata users, address[] calldata tokenAddresses) nonReentrant onlyAdmin external {
        require(users.length > 0, "DPiggyAssetManager::forceFinish: users is required");
        
        for (uint256 i = 0; i < users.length; i++) {
            _setAsset(tokenAddresses, abi.encodeWithSignature("forceFinish(address)", users[i]));
        }
    }
    
    /**
     * @dev Forwarding function to dPiggy asset to deliberately finish the user participation in all dPiggy assets.
     * All assets profit is redeemed as well as all the Dai deposited. 
     * Whether the user has the Auc escrow it will be redeemed also.
     * Only can be called by the admin.
     * Although being called by the admin, assets and Dai redeemed are done to the respective user address. 
     * @param users Array with user addresses.
     */
    function forceFinishAll(address[] calldata users) nonReentrant onlyAdmin external {
        require(users.length > 0, "DPiggyAssetManager::forceFinishAll: users is required");
        
        for (uint256 i = 0; i < users.length; i++) {
            _setAsset(assets, abi.encodeWithSignature("forceFinish(address)", users[i]));
            _redeemEscrow(users[i]);
        }
    }
    
    /**
     * @dev Function to deposit Dai on dPiggy assets.
     * Both array parameters must be the same size because the percentage is set through the same array index position.
     * @param tokenAddresses Array with ERC20 token addresses or '0x0' for Ethereum. 
     * @param percentages Array with respective assets percentage allocation (with dPiggy percentage precision).
     */
    function deposit(address[] calldata tokenAddresses, uint256[] calldata percentages) nonReentrant external {
        require(tokenAddresses.length > 0, "DPiggy::deposit: Distribution is required");
        require(tokenAddresses.length == percentages.length, "DPiggy::deposit: Invalid distribution");
        
        //The amount of Dai is the allowed quantity defined by the user for the dPiggy contract on a previous transaction.
        uint256 amount = EIP20Interface(dai).allowance(msg.sender, address(this));
        
        if (amount > 0) {
            require(EIP20Interface(dai).transferFrom(msg.sender, address(this), amount), "DPiggy::deposit: Error on transfer Dai");
            
            uint256 totalDistribution = 0;
            uint256 remainingAmount = amount;
            for (uint256 i = 0; i < tokenAddresses.length; i++) {
                AssetData storage assetData = assetsData[tokenAddresses[i]];
                
                require(assetData.depositAllowed, "DPiggy::deposit: Deposit denied");
                
                uint256 assetAmount;
                if (i == (tokenAddresses.length - 1)) {
                    //The last iterated asset gets the remaining amount to avoid rounding losses on percentage calculations.
                    assetAmount = remainingAmount;
                } else {
                    assetAmount = amount.mul(percentages[i]).div(percentagePrecision);
                    remainingAmount = remainingAmount.sub(assetAmount);
                } 
                
                require(assetAmount >= assetData.minimumDeposit, "DPiggy::deposit: Invalid amount");
                
                //Forwarding the deposit amount of Dai for the respective asset.
                require(EIP20Interface(dai).transfer(assetData.proxy, assetAmount), "DPiggy::deposit: Error on transfer Dai to asset");
                DPiggyAssetInterface(assetData.proxy).deposit(msg.sender, assetAmount);
                
                totalDistribution = totalDistribution.add(percentages[i]);
            }
            
            require(totalDistribution == percentagePrecision, "DPiggy::deposit: Invalid percentage distribution");
        }
    }

    /**
     * @dev Forwarding function to dPiggy asset to execute the Compound redeem.
     * @param tokenAddresses Array with ERC20 token addresses or '0x0' for Ethereum. The asset must already exist on dPiggy.
     */
    function executeCompoundRedeem(address[] calldata tokenAddresses) nonReentrant external {
        _setAsset(tokenAddresses, abi.encodeWithSignature("executeCompoundRedeem()"));
    }
    
    /**
     * @dev Forwarding function to dPiggy asset to redeem the asset profit.
     * @param tokenAddresses Array with ERC20 token addresses or '0x0' for Ethereum. The asset must already exist on dPiggy.
     */
    function redeem(address[] calldata tokenAddresses) nonReentrant external {
        _setAsset(tokenAddresses, abi.encodeWithSignature("forceRedeem(address)", msg.sender));
    }
    
    /**
     * @dev Forwarding function to dPiggy asset to finish the participation.
     * All assets profit is redeemed as well as all the Dai deposited.
     * @param tokenAddresses Array with ERC20 token addresses or '0x0' for Ethereum. The asset must already exist on dPiggy.
     */
    function finish(address[] calldata tokenAddresses) nonReentrant external {
        _setAsset(tokenAddresses, abi.encodeWithSignature("forceFinish(address)", msg.sender));
    }
    
    /**
     * @dev Forwarding function to dPiggy asset to finish the participation in all dPiggy assets.
     * All assets profit is redeemed as well as all the Dai deposited.
     * Whether the transaction sender has the Auc escrow it will be redeemed also.
     */
    function finishAll() nonReentrant external {
        _setAsset(assets, abi.encodeWithSignature("forceFinish(address)", msg.sender));
        _redeemEscrow(msg.sender);
    }
    
    /**
     * @dev Function to receive the Auc escrowed.
     * The sender must be the Auc token contract. It occurs after an EIP 223 transfer call.
     * On this transfer, the destination address is the dPiggy contract.
     * The user must send exactly the minimum amount of Auc to have the fee exemption and cannot already have Auc escrowed.
     * @param from The user address. 
     * @param amount Amount of Auc.
     */
    function tokenFallback(address from, uint256 amount, bytes calldata) nonReentrant external override(AucReceiverInterface) {
        require(msg.sender == address(auc), "DPiggy::tokenFallback: Invalid sender");
        require(amount == minimumAucToFreeFee, "DPiggy::tokenFallback: Invalid amount");
        
        EscrowData storage escrow = usersEscrow[from];
        require(escrow.time == 0, "DPiggy::tokenFallback: User already has an escrow");
        
        escrow.time = now;
        escrow.amount = amount;
        totalEscrow = totalEscrow.add(amount);
        
        bool escrowAdded = false;
        for (uint256 i = 0; i < assets.length; i++) {
            AssetData storage assetData = assetsData[assets[i]];
            
            //Forwarding the Auc escrowed situation for the respective asset.
            if (DPiggyAssetInterface(assetData.proxy).addEscrow(from) && !escrowAdded) {
                escrowAdded = true;
            }
        }
        require(escrowAdded, "DPiggy::tokenFallback: User without data");
        
        emit SetUserAucEscrow(from, amount);
    }
    
    /**
     * @dev Internal function to redeem the Auc escrowed.
     * It transfers the Auc escrowed for the user address and remove the escrow from the stored data.
     * @param user User's address. 
     */
    function _redeemEscrow(address user) internal {
        EscrowData storage escrow = usersEscrow[user];
        uint256 amount = escrow.amount;
        if (amount > 0) {
            escrow.time = 0;
            escrow.amount = 0;
            totalEscrow = totalEscrow.sub(amount);
            require(EIP20Interface(auc).transfer(user, amount), "DPiggy::redeemEscrow: Error on transfer escrow");
            emit RedeemUserAucEscrow(user, amount);
        }
    }
    
    /**
     * @dev Internal function to run a command on dPiggy asset.
     * @param tokenAddresses Array with ERC20 token addresses or '0x0' for Ethereum. The asset must already exist on dPiggy. 
     * @param data ABI encoded with signature data that will be called on dPiggy asset.
     */
    function _setAsset(address[] memory tokenAddresses, bytes memory data) internal {
        require(tokenAddresses.length > 0, "DPiggy::setAsset: tokenAddresses is required");
        
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            AssetData storage assetData = assetsData[tokenAddresses[i]];
            if (assetData.time > 0) {
                (bool success,) = assetData.proxy.call(data);
                assert(success);
            }
        }
    }
    
    /**
     * @dev Internal function to get a unit256 value on dPiggy asset.
     * @param tokenAddress The ERC20 token address on the chain or '0x0' for Ethereum. The asset must already exist on dPiggy. 
     * @param data ABI encoded with signature data that will be static called on dPiggy asset.
     */
    function _getValueFromAsset(address tokenAddress, bytes memory data) internal view returns(uint256) {
        AssetData storage assetData = assetsData[tokenAddress];
        if (assetData.time > 0) {
            (bool success, bytes memory returndata) = assetData.proxy.staticcall(data);
            if (success) {
                return abi.decode(returndata, (uint256));
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }
    
    function _getUint256(bytes memory data) internal pure returns(uint256[] memory) {
        uint256 size = data.length / 32;
        uint256[] memory returnUint = new uint256[](size);
        uint256 offset = 0;
        for (uint256 i = 0; i < size; ++i) {
            bytes32 number;
            for (uint256 j = 0; j < 32; j++) {
                number |= bytes32(data[offset + j] & 0xFF) >> (j * 8);
            }
            returnUint[i] = uint256(number);
            offset += 32;
        }
        return returnUint;
    }
}
