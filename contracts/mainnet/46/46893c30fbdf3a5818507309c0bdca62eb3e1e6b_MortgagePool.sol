/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

// File: iface/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// File: iface/IParassetGovernance.sol

pragma solidity ^0.8.4;

/// @dev This interface defines the governance methods
interface IParassetGovernance {
    /// @dev Set governance authority
    /// @param addr Destination address
    /// @param flag Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function setGovernance(address addr, uint flag) external;

    /// @dev Get governance rights
    /// @param addr Destination address
    /// @return Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function getGovernance(address addr) external view returns (uint);

    /// @dev Check whether the target address has governance rights for the given target
    /// @param addr Destination address
    /// @param flag Permission weight. The permission of the target address must be greater than this weight to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) external view returns (bool);
}
// File: ParassetBase.sol

pragma solidity ^0.8.4;

contract ParassetBase {

    // Lock flag
    uint256 _locked;

	/// @dev To support open-zeppelin/upgrades
    /// @param governance IParassetGovernance implementation contract address
    function initialize(address governance) public virtual {
        require(_governance == address(0), "Log:ParassetBase!initialize");
        _governance = governance;
        _locked = 0;
    }

    /// @dev IParassetGovernance implementation contract address
    address public _governance;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IParassetGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || IParassetGovernance(governance).checkGovernance(msg.sender, 0), "Log:ParassetBase:!gov");
        _governance = newGovernance;
    }

    /// @dev Uniform accuracy
    /// @param inputToken Initial token
    /// @param inputTokenAmount Amount of token
    /// @param outputToken Converted token
    /// @return stability Amount of outputToken
    function getDecimalConversion(
        address inputToken, 
        uint256 inputTokenAmount, 
        address outputToken
    ) public view returns(uint256) {
    	uint256 inputTokenDec = 18;
    	uint256 outputTokenDec = 18;
    	if (inputToken != address(0x0)) {
    		inputTokenDec = IERC20(inputToken).decimals();
    	}
    	if (outputToken != address(0x0)) {
    		outputTokenDec = IERC20(outputToken).decimals();
    	}
    	return inputTokenAmount * (10**outputTokenDec) / (10**inputTokenDec);
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(IParassetGovernance(_governance).checkGovernance(msg.sender, 0), "Log:ParassetBase:!gov");
        _;
    }

    modifier nonReentrant() {
        require(_locked == 0, "Log:ParassetBase:!_locked");
        _locked = 1;
        _;
        _locked = 0;
    }
}
// File: lib/TransferHelper.sol

pragma solidity ^0.8.4;

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
// File: iface/IPriceController.sol

pragma solidity ^0.8.4;

interface IPriceController {
    /// @dev Get price
    /// @param token mortgage asset address
    /// @param uToken underlying asset address
    /// @param payback return address of excess fee
    /// @return tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @return pTokenPrice PToken price(1 ETH = ? pToken)
    function getPriceForPToken(
    	address token, 
        address uToken,
        address payback
	) external payable returns (uint256 tokenPrice, uint256 pTokenPrice);
}
// File: iface/IInsurancePool.sol

pragma solidity ^0.8.4;

interface IInsurancePool {
    
    /// @dev Destroy ptoken, update negative ledger
    /// @param amount quantity destroyed
    function destroyPToken(uint256 amount) external;

    /// @dev Clear negative books
    function eliminate() external;
}
// File: iface/IParasset.sol

pragma solidity ^0.8.4;

interface IParasset {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function destroy(uint256 amount, address account) external;
    function issuance(uint256 amount, address account) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: MortgagePool.sol

pragma solidity ^0.8.4;

contract MortgagePool is ParassetBase {

    Config _config;
    // mortgage asset address => mortgage config
    mapping(address=>MortgageInfo) _mortgageConfig;
    // mortgage asset address => ledger info
    mapping(address=>MortgageLeader) _ledgerList;
    // priceController contract
    IPriceController _query;
    // insurance pool contract
    IInsurancePool _insurancePool;
    // contract base num
    uint256 constant BASE_NUM = 100000;

    struct MortgageInfo {
        // allow mortgage
        bool mortgageAllow;
        // six digits, 0.75=75000
        uint88 maxRate;
        // six digits, 1.3=130000
        uint80 k;
        // six digits, 0.02=2000
        uint40 r0;
        // liquidation rate 90000=90%
        uint40 liquidateRate;
    }
    struct MortgageLeader {
        // debt data
        PersonalLedger[] ledgerArray;
        // users who have created debt positions(address)
        mapping(address => uint256) accountMapping;
    }
    struct PersonalLedger {
        // amount of mortgaged assets
        uint256 mortgageAssets;
        // amount of debt(PToken,Stability fee not included)      
        uint256 parassetAssets;
        // the block height of the last operation       
        uint160 blockHeight;
        // mortgage rate(Initial mortgage rate,Mortgage rate after the last operation)           
        uint88 rate;
    }
    struct Config {
        // pToken address
        address pTokenAdd;
        // amount of blocks produced in a year            
        uint96 oneYearBlock;
        // underlyingToken address           
        address underlyingTokenAdd;
        // = 0: pause
        // = 1: active
        // = 2: out only  
        uint96 flag;                    
    }

    event FeeValue(uint256 value);
    event LedgerLog(address mToken, uint256 mTokenAmount, uint256 pTokenAmount, uint256 tokenPrice, uint256 pTokenPrice, uint88 rate);

    //---------modifier---------

    modifier whenActive() {
        require(_config.flag == 1, "Log:MortgagePool:!active");
        _;
    }

    modifier outOnly() {
        require(_config.flag != 0, "Log:MortgagePool:!0");
        _;
    }

    //---------view---------

    /// @dev Calculate the stability fee
    /// @param parassetAssets Amount of debt(PToken,Stability fee not included)
    /// @param blockHeight The block height of the last operation
    /// @param rate Mortgage rate(Initial mortgage rate,Mortgage rate after the last operation)
    /// @param nowRate Current mortgage rate (not including stability fee)
    /// @param r0Value Market base interest rate
    /// @return fee
    function getFee(
        uint256 parassetAssets, 
        uint160 blockHeight,
        uint256 rate,
        uint256 nowRate,
        uint40 r0Value
    ) public view returns(uint256) {
        uint256 top = (uint256(2) * (rate + nowRate) + BASE_NUM)
                      * parassetAssets
                      * uint256(r0Value)
                      * (block.number - uint256(blockHeight));
        uint256 bottom = BASE_NUM 
                         * BASE_NUM 
                         * uint256(_config.oneYearBlock);
        return top / bottom;
    }

    /// @dev Calculate the mortgage rate
    /// @param mortgageAssets Amount of mortgaged assets
    /// @param parassetAssets Amount of debt
    /// @param tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @param pTokenPrice PToken price(1 ETH = ? pToken)
    /// @return mortgage rate
    function getMortgageRate(
        uint256 mortgageAssets,
        uint256 parassetAssets, 
        uint256 tokenPrice, 
        uint256 pTokenPrice
    ) public pure returns(uint256) {
        if (mortgageAssets == 0) {
            return 0;
        }
    	return parassetAssets * tokenPrice * BASE_NUM / (pTokenPrice * mortgageAssets);
    }

    /// @dev Get real-time data of the current debt warehouse
    /// @param mortgageToken Mortgage asset address
    /// @param tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @param uTokenPrice Underlying asset price(1 ETH = ? Underlying asset)
    /// @param maxRateNum Maximum mortgage rate
    /// @param owner Debt owner
    /// @return fee Stability fee
    /// @return mortgageRate Real-time mortgage rate(Including stability fee)
    /// @return maxSubM The maximum amount of mortgage assets can be reduced
    /// @return maxAddP Maximum number of coins that can be added
    function getInfoRealTime(
        address mortgageToken,
        uint256 tokenPrice, 
        uint256 uTokenPrice,
        uint88 maxRateNum,
        address owner
    ) external view returns(
        uint256 fee, 
        uint256 mortgageRate, 
        uint256 maxSubM, 
        uint256 maxAddP
    ) {
        address mToken = mortgageToken;
        MortgageLeader storage mLedger = _ledgerList[mToken];
        if (mLedger.accountMapping[address(owner)] == 0) {
            return (0,0,0,0);
        }
        PersonalLedger memory pLedger = mLedger.ledgerArray[mLedger.accountMapping[address(owner)] - 1];
        if (pLedger.mortgageAssets == 0 && pLedger.parassetAssets == 0) {
            return (0,0,0,0);
        }
        uint256 pTokenPrice = getDecimalConversion(_config.underlyingTokenAdd, 
                                                   uTokenPrice, 
                                                   _config.pTokenAdd);
        uint256 tokenPriceAmount = tokenPrice;
        fee = getFee(pLedger.parassetAssets, 
                     pLedger.blockHeight, 
                     pLedger.rate, 
                     getMortgageRate(pLedger.mortgageAssets, pLedger.parassetAssets, tokenPriceAmount, pTokenPrice), 
                     _mortgageConfig[mToken].r0);
        mortgageRate = getMortgageRate(pLedger.mortgageAssets, 
                                       pLedger.parassetAssets + fee, 
                                       tokenPriceAmount, 
                                       pTokenPrice);
        uint256 mRateNum = maxRateNum;
        if (mortgageRate >= mRateNum) {
            maxSubM = 0;
            maxAddP = 0;
        } else {
            maxSubM = pLedger.mortgageAssets - (pLedger.parassetAssets * tokenPriceAmount * BASE_NUM / (mRateNum * pTokenPrice));
            maxAddP = pLedger.mortgageAssets * pTokenPrice * mRateNum / (BASE_NUM * tokenPriceAmount) - pLedger.parassetAssets;
        }
    }
    
    /// @dev View debt warehouse data
    /// @param mortgageToken mortgage asset address
    /// @param owner debt owner
    /// @return mortgageAssets amount of mortgaged assets
    /// @return parassetAssets amount of debt(PToken,Stability fee not included)
    /// @return blockHeight the block height of the last operation
    /// @return rate Mortgage rate(Initial mortgage rate,Mortgage rate after the last operation)
    /// @return created is it created
    function getLedger(
        address mortgageToken,
        address owner
    ) public view returns(
        uint256 mortgageAssets, 
        uint256 parassetAssets, 
        uint160 blockHeight,
        uint88 rate,
        bool created
    ) {
        MortgageLeader storage mLedger = _ledgerList[mortgageToken];
        if (mLedger.accountMapping[address(owner)] == 0) {
            return (0,0,0,0,false);
        }
        PersonalLedger memory pLedger = mLedger.ledgerArray[mLedger.accountMapping[address(owner)] - 1];
    	return (pLedger.mortgageAssets, 
                pLedger.parassetAssets, 
                pLedger.blockHeight, 
                pLedger.rate,
                true);
    }

    /// @dev View the insurance pool address
    /// @return insurance pool address
    function getInsurancePool() external view returns(address) {
        return address(_insurancePool);
    }

    /// @dev View the market base interest rate
    /// @return market base interest rate
    function getR0(address mortgageToken) external view returns(uint40) {
    	return _mortgageConfig[mortgageToken].r0;
    }

    /// @dev View the liquidation rate
    /// @return liquidation rate
    function getLiquidateRate(address mortgageToken) external view returns(uint40) {
    	return _mortgageConfig[mortgageToken].liquidateRate;
    }

    /// @dev View the amount of blocks produced in a year
    /// @return amount of blocks produced in a year
    function getOneYear() external view returns(uint96) {
    	return _config.oneYearBlock;
    }

    /// @dev View the maximum mortgage rate
    /// @param mortgageToken Mortgage asset address
    /// @return maximum mortgage rate
    function getMaxRate(address mortgageToken) external view returns(uint88) {
    	return _mortgageConfig[mortgageToken].maxRate;
    }

    /// @dev View the k value
    /// @param mortgageToken Mortgage asset address
    /// @return k value
    function getK(address mortgageToken) external view returns(uint256) {
        return _mortgageConfig[mortgageToken].k;
    }

    /// @dev View the priceController contract address
    /// @return priceController contract address
    function getPriceController() external view returns(address) {
        return address(_query);
    }

    /// @dev View the debt array length
    /// @param mortgageToken mortgage asset address
    /// @return debt array length
    function getLedgerArrayNum(address mortgageToken) external view returns(uint256) {
        return _ledgerList[mortgageToken].ledgerArray.length;
    }

    /// @dev View the debt index
    /// @param mortgageToken mortgage asset address
    /// @param owner debt owner
    /// @return index
    function getLedgerIndex(
        address mortgageToken, 
        address owner
    ) external view returns(uint256) {
        MortgageLeader storage mLedger = _ledgerList[mortgageToken];
        return mLedger.accountMapping[address(owner)];
    }

    /// @dev View the pToken address
    /// @return pToken address
    function getPTokenAddress() external view returns(address) {
        return _config.pTokenAdd;
    }

    /// @dev View the underlyingToken address
    /// @return underlyingToken address
    function getUnderlyingToken() external view returns(address) {
        return _config.underlyingTokenAdd;
    }

    /// @dev View the flag num
    /// @return flag num
    function getFlag() external view returns(uint96) {
        return _config.flag;
    }

    //---------governance----------

    /// @dev Set mortgage pool parameters
    /// @param pTokenAdd pToken address
    /// @param oneYear number of blocks in a year
    /// @param underlyingTokenAdd underlying asset address
    /// @param flag current state of the contract
    function setConfig(
        address pTokenAdd, 
        uint96 oneYear, 
        address underlyingTokenAdd, 
        uint96 flag
    ) public onlyGovernance {
        _config.pTokenAdd = pTokenAdd;
        _config.oneYearBlock = oneYear;
        _config.underlyingTokenAdd = underlyingTokenAdd;
        _config.flag = flag;
    }

    /// @dev Set contract status
    /// @param num 0: pause, 1: active, 2: out only
    function setFlag(uint96 num) public onlyGovernance {
        _config.flag = num;
    }

    /// @dev Allow asset mortgage to generate PToken
    /// @param mortgageToken mortgage asset address
    /// @param allow allow mortgage
    function setMortgageAllow(address mortgageToken, bool allow) public onlyGovernance {
    	_mortgageConfig[mortgageToken].mortgageAllow = allow;
    }

    /// @dev Set insurance pool contract
    /// @param add insurance pool contract
    function setInsurancePool(address add) public onlyGovernance {
        _insurancePool = IInsurancePool(add);
    }

    /// @dev Set liquidation rate
    /// @param num liquidation rate, 90000=90%
    function setLiquidateRate(address mortgageToken, uint40 num) public onlyGovernance {
    	_mortgageConfig[mortgageToken].liquidateRate = num;
    }

    /// @dev Set market base interest rate
    /// @param num market base interest rate(num = ? * 1 ether)
    function setR0(address mortgageToken, uint40 num) public onlyGovernance {
    	_mortgageConfig[mortgageToken].r0 = num;
    }

    /// @dev Set the amount of blocks produced in a year
    /// @param num amount of blocks produced in a year
    function setOneYear(uint96 num) public onlyGovernance {
    	_config.oneYearBlock = num;
    }

    /// @dev Set K value
    /// @param mortgageToken mortgage asset address
    /// @param num K value
    function setK(address mortgageToken, uint80 num) public onlyGovernance {
        _mortgageConfig[mortgageToken].k = num;
    }

    /// @dev Set the maximum mortgage rate
    /// @param mortgageToken mortgage asset address
    /// @param num maximum mortgage rate(num = ? * 1000)
    function setMaxRate(address mortgageToken, uint88 num) public onlyGovernance {
        _mortgageConfig[mortgageToken].maxRate = num;
    }

    /// @dev Set priceController contract address
    /// @param add priceController contract address
    function setPriceController(address add) public onlyGovernance {
        _query = IPriceController(add);
    }

    /// @dev Set the underlying asset and PToken mapping and
    /// @param uToken underlying asset address
    /// @param pToken PToken address
    function setInfo(address uToken, address pToken) public onlyGovernance {
        _config.pTokenAdd = pToken;
        _config.underlyingTokenAdd = uToken;
    }

    //---------transaction---------

    /// @dev Mortgage asset casting PToken
    /// @param mortgageToken mortgage asset address
    /// @param amount amount of mortgaged assets
    /// @param rate custom mortgage rate
    function coin(
        address mortgageToken,
        uint256 amount, 
        uint88 rate
    ) public payable whenActive nonReentrant {
        MortgageInfo memory morInfo = _mortgageConfig[mortgageToken];
    	require(morInfo.mortgageAllow, "Log:MortgagePool:!mortgageAllow");
        require(rate > 0 && rate <= morInfo.maxRate, "Log:MortgagePool:rate!=0");
        require(amount > 0, "Log:MortgagePool:amount!=0");
        MortgageLeader storage mLedger = _ledgerList[mortgageToken];
        uint256 ledgerNum = mLedger.accountMapping[msg.sender];
        if (ledgerNum == 0) {
            // create
            mLedger.ledgerArray.push();
            mLedger.accountMapping[msg.sender] = mLedger.ledgerArray.length;
        }
        PersonalLedger storage pLedger = mLedger.ledgerArray[mLedger.accountMapping[msg.sender] - 1];
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;

    	// Get the price and transfer to the mortgage token
        uint256 tokenPrice;
        uint256 pTokenPrice;
        if (mortgageToken != address(0x0)) {
            TransferHelper.safeTransferFrom(mortgageToken, msg.sender, address(this), amount);
            (tokenPrice, pTokenPrice) = getPriceForPToken(mortgageToken, msg.value);
        } else {
            require(msg.value >= amount, "Log:MortgagePool:!msg.value");
            (tokenPrice, pTokenPrice) = getPriceForPToken(mortgageToken, uint256(msg.value) - amount);
        }

        // Calculate the stability fee
        transferFee(pLedger, tokenPrice, pTokenPrice, morInfo.r0);

        // Additional PToken issuance
        uint256 pTokenAmount = amount * pTokenPrice * rate / (tokenPrice * BASE_NUM);
        IParasset(_config.pTokenAdd).issuance(pTokenAmount, msg.sender);

        // Update debt information
        pLedger.mortgageAssets = mortgageAssets + amount;
        pLedger.parassetAssets = parassetAssets + pTokenAmount;
        pLedger.blockHeight = uint160(block.number);
        pLedger.rate = uint88(getMortgageRate(pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice));
        emit LedgerLog(mortgageToken, pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice, pLedger.rate);
    }

    /// @dev Increase mortgage assets
    /// @param mortgageToken mortgage asset address
    /// @param amount amount of mortgaged assets
    function supplement(address mortgageToken, uint256 amount) public payable outOnly nonReentrant {
        MortgageInfo memory morInfo = _mortgageConfig[mortgageToken];
    	require(morInfo.mortgageAllow, "Log:MortgagePool:!mortgageAllow");
        require(amount > 0, "Log:MortgagePool:!amount");
        MortgageLeader storage mLedger = _ledgerList[mortgageToken];
        uint256 ledgerNum = mLedger.accountMapping[msg.sender];
        if (ledgerNum == 0) {
            // create
            mLedger.ledgerArray.push();
            mLedger.accountMapping[msg.sender] = mLedger.ledgerArray.length;
        }
        PersonalLedger storage pLedger = mLedger.ledgerArray[mLedger.accountMapping[msg.sender] - 1];
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;

    	// Get the price and transfer to the mortgage token
        uint256 tokenPrice;
        uint256 pTokenPrice;
        if (mortgageToken != address(0x0)) {
            TransferHelper.safeTransferFrom(mortgageToken, msg.sender, address(this), amount);
            (tokenPrice, pTokenPrice) = getPriceForPToken(mortgageToken, msg.value);
        } else {
            require(msg.value >= amount, "Log:MortgagePool:!msg.value");
            (tokenPrice, pTokenPrice) = getPriceForPToken(mortgageToken, uint256(msg.value) - amount);
        }

        // Calculate the stability fee
        transferFee(pLedger, tokenPrice, pTokenPrice, morInfo.r0);

        // Update debt information
    	pLedger.mortgageAssets = mortgageAssets + amount;
    	pLedger.blockHeight = uint160(block.number);
        pLedger.rate = uint88(getMortgageRate(pLedger.mortgageAssets, parassetAssets, tokenPrice, pTokenPrice));
        emit LedgerLog(mortgageToken, pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice, pLedger.rate);
    }

    /// @dev Reduce mortgage assets
    /// @param mortgageToken mortgage asset address
    /// @param amount amount of mortgaged assets
    function decrease(address mortgageToken, uint256 amount) public payable outOnly nonReentrant {
        MortgageInfo memory morInfo = _mortgageConfig[mortgageToken];
    	require(morInfo.mortgageAllow, "Log:MortgagePool:!mortgageAllow");
        MortgageLeader storage mLedger = _ledgerList[mortgageToken];
        uint256 ledgerNum = mLedger.accountMapping[msg.sender];
        require(ledgerNum != 0, "Log:MortgagePool:index=0");
        PersonalLedger storage pLedger = mLedger.ledgerArray[ledgerNum - 1];
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        require(amount > 0 && amount <= mortgageAssets, "Log:MortgagePool:!amount");

    	// Get the price
        (uint256 tokenPrice, uint256 pTokenPrice) = getPriceForPToken(mortgageToken, msg.value);

        // Calculate the stability fee
        transferFee(pLedger, tokenPrice, pTokenPrice, morInfo.r0);

        // Update debt information
    	pLedger.mortgageAssets = mortgageAssets - amount;
    	pLedger.blockHeight = uint160(block.number);
        if (pLedger.mortgageAssets == 0) {
            require(pLedger.parassetAssets == 0, "Log:MortgagePool:!parassetAssets");
            pLedger.rate == 0;
        } else {
            uint256 newRate = getMortgageRate(pLedger.mortgageAssets, parassetAssets, tokenPrice, pTokenPrice);
            // The debt warehouse mortgage rate cannot be greater than the maximum mortgage rate
    	    require(newRate <= uint256(morInfo.maxRate), "Log:MortgagePool:!maxRate");
            pLedger.rate = uint88(newRate);
        }
        emit LedgerLog(mortgageToken, pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice, pLedger.rate);

    	// Transfer out mortgage assets
    	if (mortgageToken != address(0x0)) {
            TransferHelper.safeTransfer(mortgageToken, msg.sender, amount);
    	} else {
            TransferHelper.safeTransferETH(msg.sender, amount);
    	}
    }

    /// @dev Increase debt (increase coinage)
    /// @param mortgageToken mortgage asset address
    /// @param amount amount of debt
    function increaseCoinage(address mortgageToken, uint256 amount) public payable whenActive nonReentrant {
        MortgageInfo memory morInfo = _mortgageConfig[mortgageToken];
        require(morInfo.mortgageAllow, "Log:MortgagePool:!mortgageAllow");
        require(amount > 0, "Log:MortgagePool:!amount");
        MortgageLeader storage mLedger = _ledgerList[mortgageToken];
        uint256 ledgerNum = mLedger.accountMapping[msg.sender];
        require(ledgerNum != 0, "Log:MortgagePool:index=0");
        PersonalLedger storage pLedger = mLedger.ledgerArray[ledgerNum - 1];
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        require(mortgageAssets > 0, "Log:MortgagePool:!mortgageAssets");

        // Get the price
        (uint256 tokenPrice, uint256 pTokenPrice) = getPriceForPToken(mortgageToken, msg.value);

        // Calculate the stability fee
        transferFee(pLedger, tokenPrice, pTokenPrice, morInfo.r0);

        // Update debt information
        pLedger.parassetAssets = parassetAssets + amount;
        pLedger.blockHeight = uint160(block.number);
        uint256 newRate = getMortgageRate(mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice);
        // The debt warehouse mortgage rate cannot be greater than the maximum mortgage rate
        require(newRate <= uint256(morInfo.maxRate), "Log:MortgagePool:!maxRate");
        pLedger.rate = uint88(newRate);
        emit LedgerLog(mortgageToken, pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice, pLedger.rate);

        // Additional PToken issuance
        IParasset(_config.pTokenAdd).issuance(amount, msg.sender);
    }

    /// @dev Reduce debt (increase coinage)
    /// @param mortgageToken mortgage asset address
    /// @param amount amount of debt
    function reducedCoinage(address mortgageToken, uint256 amount) public payable outOnly nonReentrant {
        MortgageInfo memory morInfo = _mortgageConfig[mortgageToken];
        require(morInfo.mortgageAllow, "Log:MortgagePool:!mortgageAllow");
        MortgageLeader storage mLedger = _ledgerList[mortgageToken];
        uint256 ledgerNum = mLedger.accountMapping[msg.sender];
        require(ledgerNum != 0, "Log:MortgagePool:index=0");
        PersonalLedger storage pLedger = mLedger.ledgerArray[ledgerNum - 1];
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        require(amount > 0 && amount <= parassetAssets, "Log:MortgagePool:!amount");

        // Get the price
        (uint256 tokenPrice, uint256 pTokenPrice) = getPriceForPToken(mortgageToken, msg.value);

        // Calculate the stability fee
        transferFee(pLedger, tokenPrice, pTokenPrice, morInfo.r0);

        // Update debt information
        pLedger.parassetAssets = parassetAssets - amount;
        pLedger.blockHeight = uint160(block.number);
        pLedger.rate = uint88(getMortgageRate(mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice));
        emit LedgerLog(mortgageToken, pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice, pLedger.rate);

        TransferHelper.safeTransferFrom(_config.pTokenAdd, 
                                        msg.sender, 
                                        address(this), 
                                        amount);
        // Destroy PToken
        IParasset(_config.pTokenAdd).destroy(amount, address(this));
    }

    /// @dev Liquidation of debt
    /// @param mortgageToken mortgage asset address
    /// @param account debt owner address
    /// @param amount amount of mortgaged assets
    /// @param pTokenAmountLimit pay PToken limit
    function liquidation(
        address mortgageToken,
        address account,
        uint256 amount,
        uint256 pTokenAmountLimit
    ) public payable outOnly nonReentrant {
        MortgageInfo memory morInfo = _mortgageConfig[mortgageToken];
    	require(morInfo.mortgageAllow, "Log:MortgagePool:!mortgageAllow");
        MortgageLeader storage mLedger = _ledgerList[mortgageToken];
        uint256 ledgerNum = mLedger.accountMapping[address(account)];
        require(ledgerNum != 0, "Log:MortgagePool:index=0");
        PersonalLedger storage pLedger = mLedger.ledgerArray[ledgerNum - 1];
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        require(amount > 0 && amount <= mortgageAssets, "Log:MortgagePool:!amount");

    	// Get the price
    	(uint256 tokenPrice, uint256 pTokenPrice) = getPriceForPToken(mortgageToken, msg.value);
        
        // Judging the liquidation line
        _checkLine(pLedger, tokenPrice, pTokenPrice, morInfo.k, morInfo.r0);

        // Calculate the amount of PToken
        uint256 pTokenAmount = amount * pTokenPrice * uint256(morInfo.liquidateRate) / (tokenPrice * BASE_NUM);
    	// Transfer to PToken
        require(pTokenAmount <= pTokenAmountLimit, "Log:MortgagePool:!pTokenAmountLimit");
        TransferHelper.safeTransferFrom(_config.pTokenAdd, msg.sender, address(_insurancePool), pTokenAmount);

        // Calculate the debt for destruction
        uint256 offset = parassetAssets * amount / mortgageAssets;

        // Destroy PToken
    	_insurancePool.destroyPToken(offset);

    	// Update debt information
    	pLedger.mortgageAssets = mortgageAssets - amount;
        pLedger.parassetAssets = parassetAssets - offset;
        emit LedgerLog(mortgageToken, pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice, pLedger.rate);

        // MortgageAssets liquidation, mortgage rate and block number are not updated
        if (pLedger.mortgageAssets == 0) {
            pLedger.parassetAssets = 0;
            pLedger.blockHeight = 0;
            pLedger.rate = 0;
        }

    	// Transfer out mortgage asset
    	if (mortgageToken != address(0x0)) {
            TransferHelper.safeTransfer(mortgageToken, msg.sender, amount);
    	} else {
            TransferHelper.safeTransferETH(msg.sender, amount);
    	}
    }

    /// @dev Check the liquidation line
    /// @param pLedger debt warehouse ledger
    /// @param tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @param pTokenPrice PToken price(1 ETH = ? pToken)
    function _checkLine(
        PersonalLedger memory pLedger, 
        uint256 tokenPrice, 
        uint256 pTokenPrice, 
        uint80 kValue,
        uint40 r0Value
    ) public view {
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;

        // The current mortgage rate cannot exceed the liquidation line
        uint256 mortgageRate = getMortgageRate(pLedger.mortgageAssets, parassetAssets, tokenPrice, pTokenPrice);
        uint256 fee = 0;
        uint160 blockHeight = pLedger.blockHeight;
        if (parassetAssets > 0 && block.number > uint256(blockHeight) && blockHeight != 0) {
            fee = getFee(parassetAssets, blockHeight, pLedger.rate, mortgageRate, r0Value);
        }
        require(((parassetAssets + fee) * uint256(kValue) * tokenPrice / (mortgageAssets * BASE_NUM)) > pTokenPrice, "Log:MortgagePool:!liquidationLine");
    }

    function transferFee(
        PersonalLedger memory pLedger, 
        uint256 tokenPrice, 
        uint256 pTokenPrice, 
        uint40 r0Value
    ) private {
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        uint256 rate = pLedger.rate;
        uint160 blockHeight = pLedger.blockHeight;
        if (parassetAssets > 0 && block.number > uint256(blockHeight) && blockHeight != 0) {
            uint256 fee = getFee(parassetAssets, 
                                 blockHeight, 
                                 rate, 
                                 getMortgageRate(mortgageAssets, parassetAssets, tokenPrice, pTokenPrice), 
                                 r0Value);

            // The stability fee is transferred to the insurance pool
            TransferHelper.safeTransferFrom(_config.pTokenAdd, 
                                            msg.sender, 
                                            address(_insurancePool), 
                                            fee);

            // Eliminate negative accounts
            _insurancePool.eliminate();
            emit FeeValue(fee);
        }
    }

    /// @dev Get price
    /// @param mortgageToken mortgage asset address
    /// @param priceValue price fee
    /// @return tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @return pTokenPrice PToken price(1 ETH = ? pToken)
    function getPriceForPToken(
        address mortgageToken,
        uint256 priceValue
    ) private returns (
        uint256 tokenPrice, 
        uint256 pTokenPrice
    ) {
        (tokenPrice, pTokenPrice) = _query.getPriceForPToken{value:priceValue}(mortgageToken, 
                                                                               _config.underlyingTokenAdd,
                                                                               msg.sender);   
    }

}