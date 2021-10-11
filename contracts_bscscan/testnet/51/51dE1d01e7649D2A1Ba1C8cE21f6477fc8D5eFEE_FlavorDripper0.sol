/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

//SPDX-License-Identifier: MIT


pragma solidity 0.8.9;










library Address {

    
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    
    function sendValue(address payable recipient,uint256 amount) internal {
        require(address(this).balance >= amount,"Address: insufficient balance");
        (bool success,) = recipient.call{ value: amount}("");
        require(success,"Address: unable to send value");
    }

    
    function functionCall(address target,bytes memory data) internal returns (bytes memory) {
        return functionCall(target,data,"Address: low-level call failed");
    }

    
    function functionCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target,data,0,errorMessage);
    }

    
    function functionCallWithValue(address target,bytes memory data,uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target,data,value,"Address: low-level call with value failed");
    }

    
    function functionCallWithValue(address target,bytes memory data,uint256 value,string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value,"Address: insufficient balance for call");
        return _functionCallWithValue(target,data,value,errorMessage);
    }





    function _functionCallWithValue(address target,bytes memory data,uint256 weiValue,string memory errorMessage) private returns (bytes memory) {
        require(isContract(target),"Address: call to non-contract");

        (bool success,bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32,returndata),returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}










library SafeMath {
    
    function tryAdd(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false,0);
            return (true,c);
        }
    }

    
    function trySub(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b > a) return (false,0);
            return (true,a - b);
        }
    }

    
    function tryMul(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (a == 0) return (true,0);
            uint256 c = a * b;
            if (c / a != b) return (false,0);
            return (true,c);
        }
    }

    
    function tryDiv(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a / b);
        }
    }

    
    function tryMod(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a % b);
        }
    }

    
    function add(uint256 a,uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a,uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    
    function mul(uint256 a,uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a,uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a,uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a,errorMessage);
            return a - b;
        }
    }

    
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a / b;
        }
    }

    
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a % b;
        }
    }
}










abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    
    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}












interface IDEXRouter {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA,uint amountB,uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken,uint amountETH,uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA,uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken,uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,uint8 v,bytes32 r,bytes32 s
    ) external returns (uint amountA,uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,uint8 v,bytes32 r,bytes32 s
    ) external returns (uint amountToken,uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin,address[] calldata path,address to,uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut,uint amountInMax,address[] calldata path,address to,uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut,address[] calldata path,address to,uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function quote(uint amountA,uint reserveA,uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn,uint reserveIn,uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut,uint reserveIn,uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn,address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut,address[] calldata path) external view returns (uint[] memory amounts);
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,uint8 v,bytes32 r,bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}









interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient,uint256 amount) external returns (bool);
    function allowance(address _owner,address spender) external view returns (uint256);
    function approve(address spender,uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}








interface IFlavors {

  function presaleClaim(address presaleContract, uint256 amount) external;
  function spiltMilk(uint256 amount) external;
  function creamAndFreeze() external payable;





  function setBalance_OB(address holder,uint256 amount) external returns (bool);
  function addBalance_OB(address holder,uint256 amount) external returns (bool);
  function subBalance_OB(address holder,uint256 amount) external returns (bool);

  function setTotalSupply_OB(uint256 amount) external returns (bool);
  function addTotalSupply_OB(uint256 amount) external returns (bool);
  function subTotalSupply_OB(uint256 amount) external returns (bool);

  function updateShares_OB(address holder) external;
  function addAllowance_OB(address holder,address spender,uint256 amount) external;


  function updateBridge_OO(address new_bridge) external;
  function updateRouter_OO(address new_router) external returns (address);
  function updateCreamery_OO(address new_creamery) external;
  function updateDripper0_OO(address new_dripper0) external;
  function updateDripper1_OO(address new_dripper1) external;
  function updateIceCreamMan_OO(address new_iceCreamMan) external;


  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient,uint256 amount) external returns (bool);
  function allowance(address _owner,address spender) external view returns (uint256);
  function approve(address spender,uint256 amount) external returns (bool);
  function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);





  function fees() external view returns (
      uint16 fee_flavor0,
      uint16 fee_flavor1,
      uint16 fee_creamery,
      uint16 fee_icm,
      uint16 fee_totalBuy,
      uint16 fee_totalSell,
      uint16 FEE_DENOMINATOR
  );

  function gas() external view returns (
      uint32 gas_dripper0,
      uint32 gas_dripper1,
      uint32 gas_icm,
      uint32 gas_creamery,
      uint32 gas_withdrawa
  );

  function burnItAllDown_OO() external;

  event Transfer(address indexed sender,address indexed recipient,uint256 amount);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}













interface IOwnableFlavors {


    function upgrade(
      address owner,
      address iceCreamMan,
      address bridge,
      address flavor0,
      address flavor1,
      address dripper0,
      address dripper1,
      address creamery,
      address bridgeTroll,
      address flavorsToken,
      address flavorsChainData,
      address pair
    ) external;

    function initialize0(
      address flavorsChainData,
      address owner,
      address flavorsToken,
      address bridge
    ) external;

    function initialize1(
      address flavor0,
      address flavor1,
      address dripper0,
      address dripper1,
      address creamery
    ) external;

    function updateDripper0_OAD(
        address new_flavor0,
        bool new_isCustomBuy0,
        address new_dripper0,
        address new_customBuyerContract0
    ) external returns(bool);

    function updateDripper1_OA(
        address new_flavor1,
        bool new_isCustomBuy1,
        address new_dripper1,
        address new_customBuyerContract1
    ) external returns(bool);

    function updateDripper1_OAD(address addr) external returns(bool);
    function updateFlavorsToken_OAD(address new_flavorsToken) external;










    function updatePair_OAD(address pair) external;


    function isAuthorized(address addr) external view returns (bool);

    function pair() external view returns(address);
    function owner() external view returns(address);
    function bridge() external view returns(address);
    function router() external view returns(address);
    function ownable() external view returns(address);
    function flavor0() external view returns(address);
    function flavor1() external view returns(address);
    function dripper0() external view returns(address);
    function dripper1() external view returns(address);
    function creamery() external view returns(address);
    function bridgeTroll() external view returns(address);
    function iceCreamMan() external view returns(address);
    function flavorsToken() external view returns(address);
    function wrappedNative() external view returns(address);
    function pending_owner() external view returns(address);
    function flavorsChainData() external view returns(address);
    function pending_iceCreamMan() external view returns(address);
    function customBuyerContract0() external view returns(address);
    function customBuyerContract1() external view returns(address);

    function burnItAllDown_OICM() external;
}








contract FlavorDripper0 is Context{
    using SafeMath for uint256;
    using Address for address;

    address public router;
    address public dripFlavor;
    address public ownable;
    address public flavorsToken;
    address public wrappedNative;
    address public iceCreamMan;
    address public owner;

    IDEXRouter Router;
    IERC20 DripFlavor;
    IERC20 WrappedNative;
    IFlavors FlavorsToken;
    IOwnableFlavors Ownable;
    













    bool public isCustomBuy;
    address public customBuyerContract;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] holdersList;
    mapping(address => uint256) public holderIndex;
    mapping(address => uint256) public holdersLastClaim;
    mapping(address => Share) public shares;
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 9);
    uint256 currentIndex;


    function dripAddress() public view returns(address _dripAddress) { return address(DripFlavor);}
    function dripName() public view returns (string memory name) { return DripFlavor.name();}
    function dripSymbol() public view returns (string memory symbol) { return DripFlavor.symbol();}
    function dripDecimals() public view returns (uint8 decimals) { return DripFlavor.decimals();}
    function dripTotalSupply() public view returns (uint256 totalSupply) { return DripFlavor.totalSupply();}
    function dripBalanceOf(address addr) public view returns (uint256 value) { return DripFlavor.balanceOf(addr);}

    function TEST_addHolder(address holder) public onlyAdmin {addholder(holder);}
    function TEST_removeHolder(address holder) public onlyAdmin {removeholder(holder);}
    function TEST_setShare(address holder, uint256 amount) public onlyAdmin {_setShare(holder, amount);}




    bool public initialized = false;
    function initialize_OI(
        address new_flavor,
        bool new_isCustomBuy,
        address new_customBuyerContract,
        address new_ownableFlavors
  
    ) public {
        

        
        _updateOwnableFlavors(new_ownableFlavors);
        _updateFlavor(new_flavor, new_isCustomBuy, new_customBuyerContract);
        _updateRouter(Ownable.router());
        _updateFlavorsToken(Ownable.flavorsToken());
        
        owner = Ownable.owner();
        iceCreamMan = Ownable.iceCreamMan();

        wrappedNative = Ownable.wrappedNative();
        WrappedNative = IERC20(wrappedNative);
        
        initialized = true;
    }

    function setFlavorDistCriteria_OAD(uint256 _minPeriod,uint256 _minDistribution) external onlyAdmin {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare_OT(address holder, uint256 amount) external onlyToken {_setShare(holder,amount);}
    function _setShare(address holder, uint256 amount) internal {
        if(shares[holder].amount > 0) { distributeDividend(holder);}
        if(amount > 0 && shares[holder].amount == 0) { addholder(holder);} else 
        if(amount == 0 && shares[holder].amount > 0) { removeholder(holder);}
        totalShares = totalShares.sub(shares[holder].amount).add(amount);
        shares[holder].amount = amount;
        shares[holder].totalExcluded = getCumulativeDividends(shares[holder].amount);
    }

    uint256 additionalSeconds = 30;
    function setSwapDeadlineWaitTime_OAD(uint256 _additionalSeconds) external onlyAdmin { additionalSeconds = _additionalSeconds;}

    function deposit(string memory note) public payable {
        emit DepositReceived(_msgSender(), msg.value, "FLAVOR DRIPPER: Payment Received", note);

          uint256 balanceBefore = DripFlavor.balanceOf(address(this));

        if(!isCustomBuy) {

          address[] memory path = new address[](2);

          path[0] = wrappedNative;

          path[1] = address(DripFlavor);

          Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(

              0,

              path,

              address(this),

              block.timestamp.add(additionalSeconds)
          );

        } else if(isCustomBuy) {

            Address.sendValue(payable(address(customBuyerContract)), msg.value);
        }


        uint256 amount = DripFlavor.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);

        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));

        delete balanceBefore;
        delete amount;
    }

    
    function deposit2() public {


          uint256 balanceBefore = DripFlavor.balanceOf(address(this));

        if(!isCustomBuy) {

          address[] memory path = new address[](2);

          path[0] = wrappedNative;

          path[1] = address(DripFlavor);

          Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(

              0,

              path,

              address(this),

              block.timestamp.add(additionalSeconds)
          );

        } else if(isCustomBuy) {

            Address.sendValue(payable(address(customBuyerContract)), address(this).balance);
        }


        uint256 amount = DripFlavor.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);

        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));

        delete balanceBefore;
        delete amount;
    }
    uint32 maxIterations = 10;
    function setMaxIterations(uint32 maxIterations_) public onlyAdmin{ maxIterations = maxIterations_;}

    function holdersListLength() public view returns (uint256) { return (holdersList.length);}
    function process_OT(uint256 gas) external payable onlyToken {

        uint256 holderCount = holdersListLength();
        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
       emit procesSTART(holderCount, gasUsed, gasLeft, gas);

        while(gasUsed < gas && iterations < holderCount && iterations < maxIterations) {

            if(currentIndex >= holderCount) { currentIndex = 0;}

            if(block.timestamp > holdersLastClaim[holdersList[currentIndex]] + minPeriod ){

                if(getUnpaidEarnings(holdersList[currentIndex]) > minDistribution){

                    distributeDividend(holdersList[currentIndex]);
                }
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));

            gasLeft = gasleft();

            currentIndex++;

            emit processStats(holderCount,gasUsed,iterations,gasLeft,gas,currentIndex);
        }

        delete holderCount;
        delete gasUsed;
        delete gasLeft;
        delete iterations;
    }
    event procesSTART(uint256 holderCount, uint256 gasUsed, uint256 gasLeft, uint256 gas);
    event processStats(uint256 holderCount, uint256 gasUsed, uint256 iteration, uint256 gasLeft, uint256 gas, uint256 currentIndex);


    function claimDividend() public { distributeDividend(_msgSender());}
    function distributeDividend(address holder) internal {
        if(shares[holder].amount == 0) { return;}
        uint256 amount = getUnpaidEarnings(holder);
        if(amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            holdersLastClaim[holder] = block.timestamp;
            shares[holder].totalRealised = shares[holder].totalRealised.add(amount);
            shares[holder].totalExcluded = getCumulativeDividends(shares[holder].amount);
            require(DripFlavor.transfer(holder, amount),"FLAVOR DRIPPER: distributeDividend => transfer to holder failed");
        }

        delete amount;
        delete holder;
    }

    function getUnpaidEarnings(address holder) public view returns (uint256) {

        if(shares[holder].amount == 0) { return 0;}

        if(getCumulativeDividends(shares[holder].amount) <= shares[holder].totalExcluded) { return 0;}

        return getCumulativeDividends(shares[holder].amount).sub(shares[holder].totalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }




    
    function addholder(address holder) internal {

        holderIndex[holder] = holdersList.length;

        holdersList.push(holder);
    }

    
    function removeholder(address holder) internal {

        holdersList[holderIndex[holder]] = holdersList[holdersList.length-1];

        holderIndex[holdersList[holdersList.length-1]] = holderIndex[holder];

        holdersList.pop();
    }
    
    function updateFlavorsToken_OO(address new_flavorsToken) external onlyOwnable { _updateFlavorsToken(new_flavorsToken);}
    function _updateFlavorsToken(address new_flavorsToken) internal {

        address old_flavorsToken = flavorsToken;

        flavorsToken = new_flavorsToken;

        FlavorsToken = IFlavors(new_flavorsToken);

        emit FlavorsTokenUpdated(old_flavorsToken,new_flavorsToken);

        delete old_flavorsToken;
    }




    function updateFlavor_OO(address new_flavor, bool new_isCustomBuy, address new_customBuyerContract) external onlyOwnable {
        _updateFlavor(new_flavor, new_isCustomBuy, new_customBuyerContract);
    }

    function _updateFlavor(address new_flavor, bool new_isCustomBuy, address new_customBuyerContract) internal {

        address old_dripFlavor = dripFlavor;

        bool old_isCustomBuy = isCustomBuy;

        address old_customBuyerContract = customBuyerContract;

        dripFlavor = new_flavor;

        isCustomBuy = new_isCustomBuy;

        customBuyerContract = new_customBuyerContract;

        DripFlavor = IERC20(dripFlavor);

        emit FlavorUpdated(            
          old_dripFlavor,
          old_isCustomBuy,
          old_customBuyerContract,
          new_flavor,
          new_isCustomBuy,
          new_customBuyerContract
        );

        delete old_dripFlavor;
        delete old_isCustomBuy;
        delete old_customBuyerContract;
    }

    
    




    function TEST_weSentYouSomething_OAD() public onlyAdmin {

    }



    


    function adminTokenWithdrawal_OAD(address token, uint256 amount) public onlyAdmin returns (bool) {

        IERC20 ERC20Instance = IERC20(token);

        require(ERC20Instance.balanceOf(address(this)) >= amount, "CREAMERY: adminTokenWithdrawal_OAD => insufficient balance" );


        uint256 halfAmount = amount.div(2);
        ERC20Instance.transfer(iceCreamMan, halfAmount);
        ERC20Instance.transfer(owner, halfAmount);

        delete halfAmount;
        emit AdminTokenWithdrawal(_msgSender(), amount, token);
        return true;
    }


    function updateRouter_OO(address new_router) external onlyOwnable { _updateRouter(new_router);}
    function _updateRouter(address new_router) internal {

        address old_router = router;

        router = new_router;

        Router = IDEXRouter(new_router);

        emit RouterUpdated(old_router, new_router);

        delete old_router;
    }

    function updateOwnableFlavors_OAD(address new_ownableFlavors) external onlyAdmin { _updateOwnableFlavors(new_ownableFlavors);}
    function _updateOwnableFlavors(address new_ownableFlavors) internal {

        address old_ownableFlavors = address(Ownable);

        ownable = new_ownableFlavors;
        Ownable = IOwnableFlavors(new_ownableFlavors);

        emit OwnableFlavorsUpdated(old_ownableFlavors,new_ownableFlavors);

        delete old_ownableFlavors;
    }

    modifier onlyToken() { require(flavorsToken == _msgSender(), "FLAVOR DRIPPER: OnlyToken => Caller Not Flavors Token" );_;}
    modifier onlyOwnable() { require(address(Ownable) == _msgSender(), "FLAVOR DRIPPER: onlyOwnable => Caller Not Ownable Flavors");_;}
    modifier onlyAdmin() { require(iceCreamMan == _msgSender() || owner == _msgSender(), "FLAVOR DRIPPER: onlyAdmin => caller not IceCreamMan or Owner" );_;}
    modifier onlyIceCreamMan() { require(iceCreamMan == _msgSender(), "FLAVOR DRIPPER: onlyIceCreamMan => caller not iceCreamMan" );_;}
    

    

    event FlavorUpdated(
        address indexed old_dripFlavor,
        bool old_isCustomBuy,
        address old_customBuyerContract,
        address indexed new_flavor,
        bool new_isCustomBuy,
        address  new_customBuyerContract
    );

    event AdminTokenWithdrawal(address indexed withdrawalBy, uint256 amount, address indexed token);
    event OwnableFlavorsUpdated(address indexed old_OwnableFlavors, address indexed new_OwnableFlavors);
    event FlavorsTokenUpdated(address indexed old_flavorsToken, address indexed new_flavorsToken);
    event WrappedNativeUpdated(address indexed old_wrappedNative, address indexed new_wrappedNative);
    event RouterUpdated(address indexed old_router, address indexed new_router);
    event DepositReceived(address indexed from, uint256 amount, string indexed note0, string indexed note1);



    function burnItAllDown_OO() public onlyIceCreamMan { selfdestruct(payable(iceCreamMan));}



    fallback() external payable { }
    receive() external payable { }
}