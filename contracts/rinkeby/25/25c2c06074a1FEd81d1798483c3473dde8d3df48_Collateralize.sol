/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

// A library for performing overflow-safe math, courtesy of DappHub: https://github.com/dapphub/ds-math/blob/d0ef6d6a5f/src/math.sol
// Modified to include only the essentials
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "MATH:: ADD_OVERFLOW");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "MATH:: SUB_UNDERFLOW");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MATH:: MUL_OVERFLOW");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "MATH:: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
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


}




// File contracts/pool/interfaces/IPool.sol

pragma solidity 0.7.4;

interface IPool {

    struct User {
        uint256 LPTokensAmount;
        uint256 TotalLPTokens;
        uint256 userStartingMCUHC;
        uint256 userStartingMCAlt;
        uint256 userStartingBalanceUHC;
        uint256 userStartingBalanceAlt;
        uint256 userAltAmount;
        uint256 userUHCAmount;
        uint256 userUHCMintAmount;
    }
    struct Utils{
        uint256  reserveUSDHAmount;
        uint256  reserveAltAmount;
        uint256  weightUSDHAmount;
        uint256  weightAltAmount;
        uint256  MCUHC;
        uint256  MCAlt;
        uint256  unlocked;
    }
    function initialize(address _token,address _token2) external;

    function addLiquidity(
        uint256 _amountALT,
        uint256 _amountUHC,
        address _owner
    )
        external
        returns (
            uint256, bytes32
        );

    function removeLiquidity(uint256 liquidity, bytes32 id) external returns (uint256, uint256, uint256);

    function swapTokens(
        address _user,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _amountInAddress
    ) external returns (uint256 result);


    function getDetails() external view returns(uint256, uint256);

    function getUHCquote() external view returns (uint256 amountB);
    function getAltquote() external view returns (uint256 amountB);
    function quote(uint256 _reserveA, uint256 _reserveB,uint256 _weightA, uint256 _weightB) external view returns (uint256 amountB);

    function getUser( bytes32 _id) external view returns(uint256, uint256,uint256);

    function getPoolWeights() external view returns(uint256,uint256);

    function getDebt(uint256 _amount,address _recipient,address _token) external;

    function getLiqPercentage( uint256 _liqAmount, bytes32 id) external view returns(uint256);

    function calcUserBalance(uint256 _liqAmount, bytes32 id) external returns(uint256 userBalanceUHC, uint256 userBalanceAlt);

    function setLiquidityOwnership(address _owner, bytes32 _id, uint256 _ownershipPercentage) external;

    function getLiquidityOwnership(address _owner, bytes32 _id) external returns(uint256);

    function updateLiquidityOwnership(address _sender, address _recipient, uint256 _liquidity, bytes32 _id) external;
}




interface ICollateralize{

struct Utils {
        address UHC_TOKEN;
        address STAKING_CONTRACT;
        address COLLATERALIZE_CONTRACT;
    }

    struct removeLiq {
        uint256 amountUHC;
        uint256 amountAlt;
        uint256 amountUHCInital;
        uint256 escrowAmount;
        uint256 debt;
        bool debt2Pay;
        bool priceIncreased;
    }

    event LiquidityRemoved(
        address pair,
        address indexed owner,
        uint256 amountALT,
        uint256 amountUHCBurn,
        uint256 liquidity,
        uint256 UserPoolPercent
    );
    event Swap(address sender, uint256 amountIn, uint256 amountOut, address pair, address amountInAddress, address amountOutAddress);


    function setRatio(address _pool, uint256 _ratio) external ;
    function setPair(address _token, address _pair) external;

    function setFactory(address _factory) external;

    function setUHC(address _factory) external;


    function collaterlizeUHC(uint256 _altAmount, address _sender,address _pool,address _uhc) external returns(
        uint256 amountUSDH,
        uint256 UHCReward,
        uint256 UHCStake, 
        uint256 amountUSDHTotal);

    function updateDataAfterSwap(address _pair, uint256 amountUSDH, bool usdhIn) external;

    function calculateDebt(uint256 amountUSDH, uint256 amountUHCInitial, address _pair) external returns(uint256 debt,bool debt2Pay);

    function calculateEscrow(address _pair,uint256 userLiq,uint256 escrowed, bytes32 _id) external returns(uint256 swapPerc);

    function uhc2Remove(uint256 uhc2Use,address _pair, bytes32 _id) external returns(uint256 liquidity);
    
    // function addLiquidity(uint256 _userEscowedAmount, uint _id, address _owner, address _pair) external;

    function removeLiquidity(address _owner, address _pair, uint256 _escrowAmount, uint256 _bone, uint256 _liqPer, bytes32 _id, bool _priceIncreased) external returns(uint256, bool);

     function addLiquidity_utils(uint256[5] memory array_utils, address[5] memory addr) external returns(uint256, bytes32);

     


}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address to, uint256 value) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 value) external returns (bool);
}

contract Collateralize is ICollateralize{
    using SafeMath for uint256;

    uint public constant BONE = 10**18;
    uint public totalUHC = 0;
    uint public TF = 259200;
    uint public multiplier = 3;

    address public FACTORY;
    mapping(address => address) public pools;
    mapping(address =>uint256) public lastTimeOfCalc;
    mapping(address =>uint256) public  poolCMA;
    mapping(address =>uint256) public  poolCVOL;
    

    mapping(address =>uint256) public poolRatios;
    mapping(address =>uint256) public lastCMAUpdated;
    mapping(address=>bool) public poolInitialized;
    //mapping(bytes32 => mapping(uint => uint256)) public userEscrowedAmount;
    mapping(bytes32 => mapping(bytes32 => uint256)) public userEscrowedAmount;

    Utils public util = Utils(address(0), address(0), address(this));
    event LiquidityAdded(address token, address pair, address indexed owner, uint256 amountALT, uint256 amountUHC, uint256 liquidity, bytes32 id);
    
    constructor(address stake_Contract) {
        util.STAKING_CONTRACT = stake_Contract;
    }

    function setFactory(address _factory) external override {
       require(FACTORY==address(0),"FS");  //FS= Factory address Set
        FACTORY = _factory;
    }

     function setUHC(address _uhcToken) external override {
        require(msg.sender== FACTORY , "OHF");  // OHF = Only Hedge Factory
        require(util.UHC_TOKEN==address(0),"UHCS");     //UHCS = UHC address set
        util.UHC_TOKEN = _uhcToken;
    }

    function setRatio(address _pool, uint256 _ratio) external override {
        poolRatios[_pool] = _ratio;
    } 


    function calculateCMAandCVO(address _pair,uint256 _price) internal {
        
        uint256 TD;
        uint256 nowTime = block.timestamp;
        if(poolCMA[_pair]==0){
            poolCMA[_pair] = _price;
            poolCVOL[_pair] = BONE;
            TD = 0;
        }
        else{
            TD = nowTime.sub(lastTimeOfCalc[_pair]);
            // console.log(TD);
        }
        uint256 CMA = poolCMA[_pair];
        uint256 CVOL = poolCVOL[_pair];
        uint256 cmaCalc1 = TF.add(TD);
        uint256 cmaCalc2 = CMA.mul(TF);
        uint256 cmaCalc3 = _price.mul(TD);
        // console.log("CMA Before",CMA);
        CMA = cmaCalc2.add(cmaCalc3).div(cmaCalc1); 
        // console.log("CMA",CMA);

        uint256 cvolCalc1 = CVOL.mul(TF).div(cmaCalc1);
        uint256 cvolCalc2 = TD.mul(BONE).div(cmaCalc1);

        uint256 cvolCalc3;
        if(CMA>=_price){
            cvolCalc3 = _price.mul(cvolCalc2).div(CMA);
        }
        else{
            cvolCalc3 = CMA.mul(cvolCalc2).div(_price);
        }

        CVOL = cvolCalc3.add(cvolCalc1);
        if(CVOL<BONE){
            CVOL = BONE;
        }
        // console.log("CVOL",CVOL);
        poolCMA[_pair] = CMA;
        poolCVOL[_pair] = CVOL;
        lastTimeOfCalc[_pair] = nowTime;
    }

    function calcFee1(address _pair,uint256 _price) internal view returns(uint256 fee1){
        if(poolCMA[_pair]<_price){
            fee1 = BONE.sub(poolCMA[_pair].mul(BONE).div(_price));
        }
        else{
            fee1 = BONE.sub(_price.mul(BONE).div(poolCMA[_pair]));
        }
    }

    function calcFee2(address _pair) internal view returns(uint256 fee2){
        fee2 = poolCVOL[_pair].sub(BONE);
    }

    function calcFee3(address _uhc,uint256 uhcMintAmount) internal view returns(uint256 fee3){
        uint256 uhcTotalSupply = IERC20(_uhc).totalSupply().add(uhcMintAmount);
        // console.log("Total Supply",uhcTotalSupply);
        uint256 uhcPoolTokens = totalUHC.mul(BONE).div(uhcTotalSupply);
        fee3 = uhcPoolTokens.mul(BONE).div(BONE.sub(uhcPoolTokens)).mul(multiplier).div(100);
        // console.log("fee 3",fee3);

    }


    function collaterlizeUHC(uint256 _altAmount, address _sender,address _pool,address _uhc) public override returns(
        uint256 amountUHC,
        uint256 UHCReward,
        uint256 UHCStake, 
        uint256 amountUHCTotal){
        require(_altAmount!=0,"Invalid Amount");
        require(_sender!=address(0),"Invalid Sender");
        
        uint256 price;
        if(!poolInitialized[_pool]){
            amountUHC = _altAmount.mul(poolRatios[_pool]).div(BONE);
            poolInitialized[_pool] = true;
            price = IPool(_pool).quote(amountUHC,_altAmount,500000000000000000, 500000000000000000);
        }
        else{
            price = IPool(_pool).getUHCquote();
            
            amountUHC = _altAmount.mul(price).div(BONE);
        }
       
        calculateCMAandCVO(_pool,price);
        totalUHC = totalUHC.add(amountUHC);

        uint256 fee1 = calcFee1(_pool, price);
        uint256 fee2 = calcFee2(_pool);
        uint256 fee3 = calcFee3(_uhc,amountUHC.mul(2));
        // console.log("Get fees",fee1,fee3);

        uint256 bestFee = fee1 >= fee2 ? fee1 : fee2;
        bestFee = bestFee>=fee3 ? bestFee:fee3;
        uint256 bestFeeinPer = bestFee;
        // console.log("Best Fee in Pair",bestFeeinPer);

        amountUHCTotal = amountUHC.mul(2);
        // console.log("amountUHC",amountUHC);
        UHCReward = amountUHC.mul(BONE.sub(bestFeeinPer)).div(BONE);


        UHCStake = (amountUHC.mul(bestFeeinPer)).div(BONE);
        
        // console.log("UHC Reward",UHCReward,UHCStake);

    }

    function updateDataAfterSwap(address _pair, uint256 amountUHC, bool UHCIn) public override {

        if(UHCIn){
            totalUHC = totalUHC.add(amountUHC);
        }
        else {
            totalUHC = totalUHC.sub(amountUHC);
        }

        uint256 _price = IPool(_pair).getUHCquote();
        calculateCMAandCVO(_pair,_price);

    }

    function calculateDebt(uint256 amountUHC, uint256 amountUHCInitial, address _pair) public override returns(uint256 debt,bool debt2Pay){
        uint256 amountUHCTotal = amountUHCInitial*2;
        if(amountUHC>amountUHCTotal){
            debt = amountUHC.sub(amountUHCTotal);
            debt2Pay = false;
        }
        else{
            debt = amountUHCTotal.sub(amountUHC);
            debt2Pay = true;

        }
        totalUHC = totalUHC.sub(amountUHC);
        uint256 _price = IPool(_pair).getAltquote();
        calculateCMAandCVO(_pair,_price);
    }

    function getPriceStatus(address _pair, bytes32 _id) internal view returns(bool _priceIncreased){
        (uint256 userInitial,,uint256 userUHCBalance) = IPool(_pair).getUser(_id);

       if(userUHCBalance+10000<userInitial){
           return false;

       }
       else{
           return true;
       }
    }

    function calculateEscrow(address _pair,uint256 userLiq,uint256 escrowed, bytes32 _id) public override returns(uint256 swapPerc){
        (uint256 userInitial,uint256 userTotalLiq,) = IPool(_pair).getUser( _id);
        uint256 userLiqPer = userLiq.mul(BONE).div(userTotalLiq);
        userInitial = userInitial.mul(userLiqPer).div(BONE);
        (uint256 userUHCBalance,) = IPool(_pair).calcUserBalance(userLiq, _id);
        uint256 debt = userInitial.mul(2).sub(userUHCBalance);
        uint256 liq2Remove = userLiq.mul(escrowed.mul(BONE).div(debt)).div(BONE);
        (,uint256 userAltBalance) = IPool(_pair).calcUserBalance(liq2Remove, _id);
        userUHCBalance = userAltBalance.mul(IPool(_pair).getUHCquote()).div(BONE);

        uint256 finalCalc1 = escrowed.sub(userUHCBalance);
        uint256 finalCalc2 = escrowed.mul(5).div(100);
        swapPerc = finalCalc2.mul(BONE).div(finalCalc1);
    }

    function uhc2Remove(uint256 uhc2Use,address _pair,bytes32 _id) public view override returns(uint256 liquidity){

       (uint256 uhcInitial,uint256 totaLiquidity,uint256 uhcAmount)= IPool(_pair).getUser( _id);

       uint256 debt = (uhcInitial*2).sub(uhcAmount);

       uint256 debtPercen = uhc2Use.mul(BONE).div(debt);

        liquidity = totaLiquidity.mul(debtPercen).div(BONE);


    }

    

    function _setTf(uint256 _tf) internal {
        TF = _tf;
    }

    function _setMultiplier(uint256 _multiplier) internal {
        multiplier = _multiplier;
    }

    function addLiquidity(uint256 _userEscowedAmount, bytes32 _id, address _owner, address _pair) internal {
        bytes32 owner_hash = keccak256(abi.encodePacked(_owner,_pair));
        userEscrowedAmount[owner_hash][_id] = userEscrowedAmount[owner_hash][_id].add(_userEscowedAmount);
        // console.log("Ecr Amnt in Collateralize ",userEscrowedAmount[_owner]);
    }

    function removeLiquidity(address _owner, address _pair, uint256 _escrowAmount, uint256 _bone, uint256 _liqPer, bytes32 _id, bool _priceIncreased) public override returns(uint256, bool){
        bytes32 owner_hash = keccak256(abi.encodePacked(_owner,_pair));
        if(userEscrowedAmount[owner_hash][_id]>0){
            _escrowAmount = userEscrowedAmount[owner_hash][_id].mul(_liqPer).div(_bone);
            userEscrowedAmount[owner_hash][_id] = userEscrowedAmount[owner_hash][_id].sub(_escrowAmount);
            _priceIncreased = getPriceStatus(_pair, _id);
        }
        return (_escrowAmount, _priceIncreased);
    }

    function addLiquidity_utils(uint256[5] memory array_utils, address[5] memory addr) public override returns(uint256, bytes32){
        (uint256  liquidity, bytes32 id) = IPool(addr[1]).addLiquidity(array_utils[3], array_utils[4], addr[0]);
        uint256 userEscowedAmount = array_utils[4].mul(array_utils[2]).div(BONE);
        addLiquidity(userEscowedAmount, id, addr[0], addr[1]);
        if(array_utils[2] < BONE){
            uint256 transferAmount = array_utils[0].mul(BONE.sub(array_utils[2])).div(BONE);
            IERC20(addr[2]).transfer(addr[0], transferAmount);
            transferAmount = array_utils[1].mul(BONE.sub(array_utils[2])).div(BONE);
            IERC20(addr[2]).transfer(addr[3], transferAmount);
        }
        //IERC20(addr[2]).transfer(msg.sender,userEscowedAmount);
        IPool(addr[1]).setLiquidityOwnership(addr[0],id,100*BONE);
        return (liquidity,id);
    }

    function setPair(address _token, address _pair) external override{
        require(pools[_token] == address(0), "PE");
        require(msg.sender== FACTORY , "OHF");
        pools[_token]=_pair;
        IERC20(util.UHC_TOKEN).approve(_pair,uint(-1));
        IERC20(_token).approve(_pair,uint(-1));
        IERC20(_pair).approve(_pair,uint(-1));
    }

    function addLiquidityInPool(
        uint256 amountAlt,
        address _token,
        uint256 _escrowedPercent
    ) external returns(uint256 liquidity, bytes32 id){
        address owner = msg.sender;
        address pair = pools[_token];
        require(_escrowedPercent >= 0 && _escrowedPercent <= BONE && pair != address(0) && amountAlt > 0, "I%");

        (uint256 _amountUHC, uint256 userLiquidityReward, uint256 stakeAmount, uint256 amountUHCTotal) = collaterlizeUHC(amountAlt, owner, pair, util.UHC_TOKEN);

        IERC20(util.UHC_TOKEN).mint(address(this), amountUHCTotal);
        IERC20(_token).transferFrom(owner, address(this), amountAlt);

        // (uint256  liquidity, uint id) = IPool(pair).addLiquidity(amountAlt,_amountUHC, owner);
        // uint256[] memory array_utils = new uint256[](5);
        // address[] memory addr = new address[](5);
        // array_utils[0] = userLiquidityReward;
        // array_utils[1] = stakeAmount;
        // array_utils[2] = _escrowedPercent;
        // array_utils[3] = amountAlt;
        // array_utils[4] = _amountUHC;
        // addr[0] = owner;
        // addr[1] = pair;
        // addr[2] = util.UHC_TOKEN;
        // addr[3] = util.STAKING_CONTRACT;
        // addr[4] = _token;

        (liquidity, id)=addLiquidity_utils(
            [userLiquidityReward, stakeAmount, _escrowedPercent, amountAlt, _amountUHC],
            [owner, pair, util.UHC_TOKEN, util.STAKING_CONTRACT, _token]
        );
        // uint256 userEscowedAmount = _amountUHC.mul(_escrowedPercent).div(BONE);
        // ICollateralize(util.COLLATERALIZE_CONTRACT).addLiquidity(userEscowedAmount, id, owner, pair);
        // if(_escrowedPercent < BONE){
        // uint256 transferAmount = userLiquidityReward.mul(BONE.sub(_escrowedPercent)).div(BONE);
        // IERC20(util.UHC_TOKEN).transfer(owner, transferAmount);
        // transferAmount = stakeAmount.mul(BONE.sub(_escrowedPercent)).div(BONE);
        // IERC20(util.UHC_TOKEN).transfer(address(util.STAKING_CONTRACT), transferAmount);
        // }
        emit LiquidityAdded(_token, pair, owner, amountAlt, _amountUHC, liquidity, id);
    }

    function swap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[4] memory sw
    ) public returns (uint256 result) {
        address pair = pools[sw[3]];
        require(pair != address(0) && amountIn > 0, "PDE");
        // require(, "IA");
        if (sw[2] != address(this)) {
            IERC20(sw[0]).transferFrom(sw[2], address(this), amountIn);
        }
        (uint256 uhcAmount, bool usdin) = sw[0] == util.UHC_TOKEN ? (amountIn, true) : (result, false);
        result = IPool(pair).swapTokens(sw[2], amountIn, amountOutMin, sw[0]);
        updateDataAfterSwap(pair, uhcAmount, usdin);

        // IVault(VAULT_CONTRACT).withdrawFunds(amountOutAddress,user,result);

        emit Swap(sw[2], amountIn, result, pair, sw[0], sw[1]);
    }

    function removeLiquidityInPool(
        uint256 liquidity,
        bytes32 id,
        address token
    ) external {
        removeLiq memory utils_removeLiq = removeLiq(0, 0, 0, 0, 0, false, true);
        address owner = msg.sender;
        address pair = pools[token];

        require(pair != address(0), "PDE");
        require(IERC20(pair).balanceOf(owner) >= liquidity, "IL");
        IERC20(pair).transferFrom(owner, address(this), liquidity);

        uint256 liqPer = IPool(pair).getLiqPercentage( liquidity, id);
        (utils_removeLiq.escrowAmount, utils_removeLiq.priceIncreased) = removeLiquidity(
                owner,
                pair,
                utils_removeLiq.escrowAmount,
                BONE,
                liqPer,
                id,
                utils_removeLiq.priceIncreased
            );
        if (!utils_removeLiq.priceIncreased) {
            address tempToken = token;
            uint256 tempLiq = liquidity;
            uint256 removePer = calculateEscrow(
                pair,
                tempLiq,
                utils_removeLiq.escrowAmount,
                id
            );

            uint256 swapAmount = utils_removeLiq.escrowAmount.mul(BONE.sub(removePer)).div(BONE);

            bytes32 id2 = id;
            uint256 removeAmount = utils_removeLiq.escrowAmount.mul(removePer).div(BONE);
            // uint256 removeAmount = utils_removeLiq.escrowAmount.mul(BONE.sub(swapPer)).div(BONE);
            // SwapUtils memory sw = SwapUtils(swapAmount,1,[util.UHC_TOKEN,tempToken, address(this), tempToken]);
            swap(swapAmount, 1, [util.UHC_TOKEN, tempToken, address(this), tempToken]);
            uint256 liquidity2Remove = uhc2Remove(
                removeAmount,
                pair,
                id2
            );
            IERC20(pair).transfer(0x015CadF4ea1806582F7098e72af296795Bde1710, tempLiq.sub(liquidity2Remove));
            (utils_removeLiq.amountUHC, utils_removeLiq.amountAlt, utils_removeLiq.amountUHCInital) = IPool(pair)
                .removeLiquidity(liquidity2Remove, id2);
            (utils_removeLiq.debt, utils_removeLiq.debt2Pay) = (removeAmount, true);
            utils_removeLiq.escrowAmount = 0;
        } else {
            bytes32 id2 = id;
            (utils_removeLiq.amountUHC, utils_removeLiq.amountAlt, utils_removeLiq.amountUHCInital) = IPool(pair)
                .removeLiquidity(liquidity, id2);

            (utils_removeLiq.debt, utils_removeLiq.debt2Pay) = calculateDebt(utils_removeLiq.amountUHC, utils_removeLiq.amountUHCInital, pair);

            if (utils_removeLiq.priceIncreased && utils_removeLiq.escrowAmount != 0) {
                utils_removeLiq.escrowAmount = utils_removeLiq.debt2Pay
                    ? utils_removeLiq.escrowAmount.sub(utils_removeLiq.debt)
                    : utils_removeLiq.escrowAmount;
                utils_removeLiq.debt = 0;
            }
        }

        IERC20(token).transfer(owner, utils_removeLiq.amountAlt);

        if (!utils_removeLiq.debt2Pay || utils_removeLiq.debt == 0) {
            if (utils_removeLiq.debt > 0) {
                utils_removeLiq.escrowAmount = utils_removeLiq.escrowAmount.add(utils_removeLiq.debt);
            }
            IERC20(util.UHC_TOKEN).burn(utils_removeLiq.amountUHC.sub(utils_removeLiq.debt));
        } else {
            if (utils_removeLiq.priceIncreased) {
                // console.log("Liq Debt ",utils_removeLiq.debt);
                // console.log("Balance in Contract ", IERC20(util.UHC_TOKEN).balanceOf(owner));
                IERC20(util.UHC_TOKEN).transferFrom(owner, address(this), utils_removeLiq.debt);
            }

            IERC20(util.UHC_TOKEN).burn(utils_removeLiq.debt.add(utils_removeLiq.amountUHC));
            utils_removeLiq.escrowAmount = 0;
        }

        if (utils_removeLiq.escrowAmount > 0) {
            IERC20(util.UHC_TOKEN).transfer(owner, utils_removeLiq.escrowAmount);
        }

        IPool(pair).updateLiquidityOwnership(owner, address(0), liquidity, id);


        emit LiquidityRemoved(
            pair,
            owner,
            utils_removeLiq.amountAlt,
            utils_removeLiq.debt,
            liquidity,
            utils_removeLiq.amountUHC
        );
    }

    // function getDetails(address _poolAddress) external view returns(uint256, uint256) {
    //     return IPool(_poolAddress).getDetails();
    // }

    // function getPoolWeights(address _poolAddress) external view returns(uint256,uint256){
    //     return IPool(_poolAddress).getPoolWeights();
    // }

}