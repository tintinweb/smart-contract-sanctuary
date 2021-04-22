// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

// Interfaces
import "./interfaces/iERC20.sol";
import "./interfaces/iUTILS.sol";
import "./interfaces/iUSDV.sol";
import "./interfaces/iROUTER.sol";

contract Vader is iERC20 {

    // ERC-20 Parameters
    string public override name; string public override symbol;
    uint public override decimals; uint public override totalSupply;

    // ERC-20 Mappings
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    // Parameters
    bool private inited;
    bool public emitting;
    bool public minting;
    uint _1m;
    uint public baseline;
    uint public emissionCurve;
    uint public maxSupply;
    uint public secondsPerEra;
    uint public currentEra;
    uint public nextEraTime;
    uint public feeOnTransfer;

    address public VETHER;
    address public USDV;
    address public UTILS;
    address public burnAddress;
    address public rewardAddress;
    address public DAO;

    event NewEra(uint currentEra, uint nextEraTime, uint emission);

    // Only DAO can execute
    modifier onlyDAO() {
        require(msg.sender == DAO, "Not DAO");
        _;
    }
    // Stop flash attacks
    modifier flashProof() {
        require(isMature(), "No flash");
        _;
    }
    function isMature() public view returns(bool){
        return iUSDV(USDV).isMature();
    }

    //=====================================CREATION=========================================//
    // Constructor
    constructor() {
        name = 'VADER PROTOCOL TOKEN';
        symbol = 'VADER';
        decimals = 18;
        _1m = 10**6 * 10 ** decimals; //1m
        baseline = _1m;
        totalSupply = 0;
        maxSupply = 2 * _1m;
        currentEra = 1;
        secondsPerEra = 1; //86400;
        nextEraTime = block.timestamp + secondsPerEra;
        emissionCurve = 900;
        DAO = msg.sender;
        burnAddress = 0x0111011001100001011011000111010101100101;
    }
    // Can only be called once
    function init(address _vether, address _USDV, address _utils) external {
        require(inited == false);
        inited = true;
        VETHER = _vether;
        USDV = _USDV;
        UTILS = _utils;
        rewardAddress = _USDV;
    }

    //========================================iERC20=========================================//
    function balanceOf(address account) external view override returns (uint) {
        return _balances[account];
    }
    function allowance(address owner, address spender) public view virtual override returns (uint) {
        return _allowances[owner][spender];
    }
    // iERC20 Transfer function
    function transfer(address recipient, uint amount) external virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    // iERC20 Approve, change allowance functions
    function approve(address spender, uint amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "sender");
        require(spender != address(0), "spender");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    // iERC20 TransferFrom function
    function transferFrom(address sender, address recipient, uint amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    // TransferTo function
    // Risks: User can be phished, or tx.origin may be deprecated, optionality should exist in the system. 
    function transferTo(address recipient, uint amount) external virtual override returns (bool) {
        _transfer(tx.origin, recipient, amount);
        return true;
    }

    // Internal transfer function
    function _transfer(address sender, address recipient, uint amount) internal virtual {
        require(sender != address(0), "sender");
        require(recipient != address(this), "recipient");
        _balances[sender] -= amount;
        uint _fee = iUTILS(UTILS).calcPart(feeOnTransfer, amount);  // Critical functionality
        if(_fee >= 0 && _fee <= amount){                            // Stops reverts if UTILS corrupted
            amount -= _fee;
            _burn(msg.sender, _fee);
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _checkEmission();
    }
    // Internal mint (upgrading and daily emissions)
    function _mint(address account, uint amount) internal virtual {
        require(account != address(0), "recipient");
        if((totalSupply + amount) >= maxSupply){
            amount = maxSupply - totalSupply;       // Safety, can't mint above maxSupply
        }
        totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    // Burn supply
    function burn(uint amount) public virtual override {
        _burn(msg.sender, amount);
    }
    function burnFrom(address account, uint amount) external virtual override {
        uint decreasedAllowance = allowance(account, msg.sender) - amount;
        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
    }
    function _burn(address account, uint amount) internal virtual {
        require(account != address(0), "address err");
        _balances[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    //=========================================DAO=========================================//
    // Can start
    function flipEmissions() external onlyDAO {
        if(emitting){
            emitting = false;
        } else {
            emitting = true;
        }
    }
    // Can stop
    function flipMinting() external onlyDAO {
        if(minting){
            minting = false;
        } else {
            minting = true;
        }
    }
    // Can set params
    function setParams(uint newEra, uint newCurve) external onlyDAO {
        secondsPerEra = newEra;
        emissionCurve = newCurve;
    }
    // Can set reward address
    function setRewardAddress(address newAddress) external onlyDAO {
        rewardAddress = newAddress;
    }
    // Can change UTILS
    function changeUTILS(address newUTILS) external onlyDAO {
        require(newUTILS != address(0), "address err");
        UTILS = newUTILS;
    }
    // Can change DAO
    function changeDAO(address newDAO) external onlyDAO {
        require(newDAO != address(0), "address err");
        DAO = newDAO;
    }
    // Can purge DAO
    function purgeDAO() external onlyDAO{
        DAO = address(0);
    }

   //======================================EMISSION========================================//
    // Internal - Update emission function
    function _checkEmission() private {
        if ((block.timestamp >= nextEraTime) && emitting) {                                // If new Era and allowed to emit
            currentEra += 1;                                                               // Increment Era
            nextEraTime = block.timestamp + secondsPerEra;                                 // Set next Era time
            uint _emission = getDailyEmission();                                           // Get Daily Dmission
            _mint(rewardAddress, _emission);                                               // Mint to the Rewad Address
            feeOnTransfer = iUTILS(UTILS).getFeeOnTransfer(totalSupply, maxSupply);        // UpdateFeeOnTransfer
            if(feeOnTransfer > 1000){feeOnTransfer = 1000;}                                // Max 10% if UTILS corrupted
            emit NewEra(currentEra, nextEraTime, _emission);                               // Emit Event
        }
    }
    // Calculate Daily Emission
    function getDailyEmission() public view returns (uint) {
        uint _adjustedMax;
        if(totalSupply <= baseline){ // If less than 1m, then adjust cap down
            _adjustedMax = (maxSupply * totalSupply) / baseline; // 2m * 0.5m / 1m = 2m * 50% = 1.5m
        } else {
            _adjustedMax = maxSupply;  // 2m
        }
        return (_adjustedMax - totalSupply) / (emissionCurve); // outstanding / curve 
    }

    //======================================ASSET MINTING========================================//
    // VETHER Owners to Upgrade
    function upgrade(uint amount) external {
        require(iERC20(VETHER).transferFrom(msg.sender, burnAddress, amount));
        _mint(msg.sender, amount);
    }
    // Directly redeem back to VADER (must have sent USDV first)
    function redeem() external returns (uint redeemAmount){
        return redeemToMember(msg.sender);
    }
    // Redeem on behalf of member (must have sent USDV first)
    function redeemToMember(address member) public flashProof returns (uint redeemAmount){
        if(minting){
            uint _amount = iERC20(USDV).balanceOf(address(this)); 
            iERC20(USDV).burn(_amount);
            redeemAmount = iROUTER(iUSDV(USDV).ROUTER()).getVADERAmount(_amount); // Critical pricing functionality
            _mint(member, redeemAmount);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function transferTo(address, uint) external returns (bool);
    function burn(uint) external;
    function burnFrom(address, uint) external;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iROUTER {
    function setParams(uint newFactor, uint newTime, uint newLimit) external;
    function addLiquidity(address base, uint inputBase, address token, uint inputToken) external returns(uint);
    function removeLiquidity(address base, address token, uint basisPoints) external returns (uint amountBase, uint amountToken);
    function swap(uint inputAmount, address inputToken, address outputToken) external returns (uint outputAmount);
    function swapWithLimit(uint inputAmount, address inputToken, address outputToken, uint slipLimit) external returns (uint outputAmount);
    function swapWithSynths(uint inputAmount, address inputToken, bool inSynth, address outputToken, bool outSynth) external returns (uint outputAmount);
    function swapWithSynthsWithLimit(uint inputAmount, address inputToken, bool inSynth, address outputToken, bool outSynth, uint slipLimit) external returns (uint outputAmount);
    
    function getILProtection(address member, address base, address token, uint basisPoints) external view returns(uint protection);
    
    function curatePool(address token) external;
    function listAnchor(address token) external;
    function replacePool(address oldToken, address newToken) external;
    function updateAnchorPrice(address token) external;
    function getAnchorPrice() external view returns (uint anchorPrice);
    function getVADERAmount(uint USDVAmount) external view returns (uint vaderAmount);
    function getUSDVAmount(uint vaderAmount) external view returns (uint USDVAmount);
    function isCurated(address token) external view returns(bool curated);

    function reserveUSDV() external view returns(uint);
    function reserveVADER() external view returns(uint);

    function getMemberBaseDeposit(address member, address token) external view returns(uint);
    function getMemberTokenDeposit(address member, address token) external view returns(uint);
    function getMemberLastDeposit(address member, address token) external view returns(uint);
    function getMemberCollateral(address member, address collateralAsset, address debtAsset) external view returns(uint);
    function getMemberDebt(address member, address collateralAsset, address debtAsset) external view returns(uint);
    function getSystemCollateral(address collateralAsset, address debtAsset) external view returns(uint);
    function getSystemDebt(address collateralAsset, address debtAsset) external view returns(uint);
    function getSystemInterestPaid(address collateralAsset, address debtAsset) external view returns(uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iUSDV {
    function ROUTER() external view returns (address);
    function totalWeight() external view returns(uint);
    function totalRewards() external view returns(uint);
    function isMature() external view returns (bool);
    function setParams(uint newEra, uint newDepositTime, uint newDelay, uint newGrantTime) external;
    function grant(address recipient, uint amount) external;
    function convert(uint amount) external returns(uint convertAmount);
    function convertForMember(address member, uint amount) external returns(uint convertAmount);
    function redeem(uint amount) external returns(uint redeemAmount);
    function redeemForMember(address member, uint amount) external returns(uint redeemAmount);
    function deposit(address token, uint amount) external;
    function depositForMember(address token, address member, uint amount) external;
    function harvest(address token) external returns(uint reward);
    function calcCurrentReward(address token, address member) external view returns(uint reward);
    function calcReward(address member) external view returns(uint);
    function withdraw(address token, uint basisPoints) external returns(uint redeemedAmount);
    function reserveUSDV() external view returns(uint);
    function getTokenDeposits(address token) external view returns(uint);
    function getMemberReward(address token, address member) external view returns(uint);
    function getMemberWeight(address member) external view returns(uint);
    function getMemberDeposit(address token, address member) external view returns(uint);
    function getMemberLastTime(address token, address member) external view returns(uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iUTILS {
    function getFeeOnTransfer(uint totalSupply, uint maxSupply) external pure returns (uint);
    function assetChecks(address collateralAsset, address debtAsset) external;
    function isBase(address token) external view returns(bool base);

    function calcValueInBase(address token, uint amount) external view returns (uint);
    function calcValueInToken(address token, uint amount) external view returns (uint);
    function calcValueOfTokenInToken(address token1, uint amount, address token2) external view returns (uint);
    function calcSwapValueInBase(address token, uint amount) external view returns (uint);
    function calcSwapValueInToken(address token, uint amount) external view returns (uint);
    function requirePriceBounds(address token, uint bound, bool inside, uint targetPrice) external view;

    function getRewardShare(address token, uint rewardReductionFactor) external view returns (uint rewardShare);
    function getReducedShare(uint amount) external view returns(uint);

    function getProtection(address member, address token, uint basisPoints, uint timeForFullProtection) external view returns(uint protection);
    function getCoverage(address member, address token) external view returns (uint);
    
    function getCollateralValueInBase(address member, uint collateral, address collateralAsset, address debtAsset) external returns (uint debt, uint baseValue);
    function getDebtValueInCollateral(address member, uint debt, address collateralAsset, address debtAsset) external view returns(uint, uint);
    function getInterestOwed(address collateralAsset, address debtAsset, uint timeElapsed) external returns(uint interestOwed);
    function getInterestPayment(address collateralAsset, address debtAsset) external view returns(uint);
    function getDebtLoading(address collateralAsset, address debtAsset) external view returns(uint);

    function calcPart(uint bp, uint total) external pure returns (uint);
    function calcShare(uint part, uint total, uint amount) external pure returns (uint);
    function calcSwapOutput(uint x, uint X, uint Y) external pure returns (uint);
    function calcSwapFee(uint x, uint X, uint Y) external pure returns (uint);
    function calcSwapSlip(uint x, uint X) external pure returns (uint);
    function calcLiquidityUnits(uint b, uint B, uint t, uint T, uint P) external view returns (uint);
    function getSlipAdustment(uint b, uint B, uint t, uint T) external view returns (uint);
    function calcSynthUnits(uint b, uint B, uint P) external view returns (uint);
    function calcAsymmetricShare(uint u, uint U, uint A) external pure returns (uint);
    function calcCoverage(uint B0, uint T0, uint B1, uint T1) external pure returns(uint);
    function sortArray(uint[] memory array) external pure returns (uint[] memory);
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