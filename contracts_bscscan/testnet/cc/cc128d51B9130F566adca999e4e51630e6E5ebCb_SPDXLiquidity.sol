// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol"; 
import "./TransferHelper.sol";

interface Token{
        function decimals() external view returns(uint256);
        function symbol() external view returns(string memory);
        function totalSupply() external view returns (uint256);
        function balanceOf(address who) external view returns (uint256);
        function transfer(address to, uint256 value) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
        function transferFrom(address from, address to, uint256 value) external returns (bool);
        function approve(address spender, uint256 value) external returns (bool);
        function burn(address from, uint256 value) external returns (bool);
        function mint(address to, uint256 value) external returns (bool);
    }

contract SPDXLiquidity is Ownable,ReentrancyGuard{
    
    using SafeMath for uint256;
    uint256 public poolCount;
    struct TokenPair{
        uint256 amountTokenA;
        uint256 amountTokenB;
        uint256 lPoolTokens;
        address addressTokenA;
        address addressTokenB;
    }
    uint256 public constant decimalFactorBNB=10**18;
    mapping(uint256=>TokenPair) public pairMapping;
    mapping(address=>mapping(address=>uint256)) public pairIndexTokensMapping;
    mapping(address=>uint256) public pairIndexBNBMapping;
    address public poolTokenAddress=0x7a9B287e902645E1A5d4D39F67CA94fd9BBcc484;
    
    event addLiquidityEventTokenToToken(address _tokenA, address _tokenB, address indexed userAddress, 
                                        uint256 _amountTokenA, uint256 _amountTokenB,uint256 timestamp, uint256 LPTokenAmount);
                                        
    event addLiquidityEventBNBToToken(address _token, address indexed userAddress, 
                                        uint256 _BNBAmount, uint256 _amountToken,uint256 timestamp, uint256 LPTokenAmount);
                                        
    
    event removeLiquidityEventTokenToToken(address _tokenA, address _tokenB, address indexed userAddress, 
                                        uint256 _amountTokenA, uint256 _amountTokenB,uint256 timestamp, uint256 LPTokenAmount);
                                        
    event removeLiquidityEventBNBToToken(address _token, address indexed userAddress, 
                                        uint256 _BNBAmount, uint256 _amountToken,uint256 timestamp, uint256 LPTokenAmount);
                                        
    event swapEvent(address _tokenA, address _tokenB, uint256 _amountTokenA, uint256 _amountTokenB);
    
    struct UserPairs{
        bool isAvailable;
        uint256 lPoolTokens;
    }
    mapping(address=>mapping(uint256=>UserPairs)) public userPairsMapping;
    uint256 public swappingFee=300;//in 10**3
    
    bool isInitialized;
    
    address public adminShareReceivingAddress=0xE380a93Db38f46866fdf4Ca86005cb51CC259771;
    uint256 public adminShare=1000;//in 10**3
    address public burnAddress=0x000000000000000000000000000000000000dEaD;
    
      function initialize(address _poolTokenAddress,uint256 _swappingFee,address owner, 
                            address _adminShareReceivingAddress,uint256 _adminShare, address _burnAddress) public {
        require(!isInitialized,"Already initialized");
        _setOwner(owner);
        poolTokenAddress = _poolTokenAddress;
        swappingFee=_swappingFee;
        isInitialized = true;
        adminShareReceivingAddress = _adminShareReceivingAddress;
        adminShare = _adminShare;
        burnAddress = _burnAddress;
    }
    
    function addLiquidityForTokenToToken(address _tokenA, address _tokenB, 
                                            uint256 _amountTokenA, uint256 _amountTokenB,
                                            uint256 _minAmountA, uint256 _minAmountB) external nonReentrant{
        helperMessagesTokens(_tokenA,_amountTokenA);
        helperMessagesTokens(_tokenB,_amountTokenB);
        uint256 LPTokens=(sqrt(((_amountTokenA.mul(_amountTokenB))
                            .mul(10**Token(poolTokenAddress).decimals()).mul(10**Token(poolTokenAddress).decimals())).div((10**(Token(_tokenA).decimals())).mul(10**(Token(_tokenB).decimals())))));
        uint256 adminValue=(adminShare.mul(LPTokens)).div(10**5);
        uint256 indexValue=pairIndexTokensMapping[_tokenA][_tokenB];
        if(pairMapping[indexValue].addressTokenA==_tokenA 
            || pairMapping[indexValue].addressTokenA==_tokenB){
            helperSlipage(_tokenB,_tokenA,_amountTokenB,_amountTokenA,_minAmountB,_minAmountA,false);
            TokenPair storage pairInfo=pairMapping[indexValue];
            pairInfo.lPoolTokens=pairInfo.lPoolTokens.add(LPTokens);
            if(pairInfo.addressTokenA==_tokenA){
                pairInfo.amountTokenA= pairInfo.amountTokenA.add(_amountTokenA);
                pairInfo.amountTokenB= pairInfo.amountTokenB.add(_amountTokenB);
            }else {
                pairInfo.amountTokenA= pairInfo.amountTokenA.add(_amountTokenB);
                pairInfo.amountTokenB= pairInfo.amountTokenB.add(_amountTokenA);
            }
            userPairsMapping[msg.sender][indexValue].isAvailable=true;
            userPairsMapping[msg.sender][indexValue].lPoolTokens=(userPairsMapping[msg.sender][indexValue].lPoolTokens).add(LPTokens.sub(adminValue));
        }else{
            poolCount=poolCount.add(1);
            TokenPair memory pairInfo=TokenPair({
                amountTokenA:_amountTokenA,
                amountTokenB:_amountTokenB,
                lPoolTokens: LPTokens,
                addressTokenA:_tokenA,
                addressTokenB:_tokenB
            });
            pairMapping[poolCount]=pairInfo;
            pairIndexTokensMapping[_tokenA][_tokenB]=poolCount;
            pairIndexTokensMapping[_tokenB][_tokenA]=poolCount;
            UserPairs memory userPairInfo= UserPairs({
                isAvailable:true,
                lPoolTokens:LPTokens.sub(adminValue)
            });
            userPairsMapping[msg.sender][poolCount]=userPairInfo;
        }
        TransferHelper.safeTransferFrom(_tokenA,msg.sender,address(this),_amountTokenA);
        TransferHelper.safeTransferFrom(_tokenB,msg.sender,address(this),_amountTokenB);
        Token(poolTokenAddress).mint(msg.sender,LPTokens.sub(adminValue));
        Token(poolTokenAddress).mint(adminShareReceivingAddress,adminValue);
        userPairsMapping[adminShareReceivingAddress][poolCount].isAvailable=true;
        userPairsMapping[adminShareReceivingAddress][poolCount].lPoolTokens=userPairsMapping[adminShareReceivingAddress][poolCount].lPoolTokens.add(adminValue);
        emit addLiquidityEventTokenToToken(_tokenA,_tokenB,adminShareReceivingAddress,_amountTokenA, _amountTokenB, block.timestamp, adminValue);
        emit addLiquidityEventTokenToToken(_tokenA,_tokenB,msg.sender,_amountTokenA, _amountTokenB, block.timestamp, LPTokens.sub(adminValue));
    }
    
    function addliquidityForBNBToTokens(address tokenAddress, uint256 tokenAmount, 
                                        uint256 minBNBAmount, uint256 minTokenAmount) external payable nonReentrant{
        helperMessagesTokens(tokenAddress,tokenAmount);
        require(msg.value>0,"Please enter BNB amount more than 0");
        uint256 LPTokens=(sqrt((msg.value.mul(tokenAmount).mul(10**Token(poolTokenAddress).decimals()).mul(10**Token(poolTokenAddress).decimals()))
                                .div((10**(Token(tokenAddress).decimals())).mul(decimalFactorBNB))));
        uint256 adminValue=(adminShare.mul(LPTokens)).div(10**5);
        uint256 indexValue=pairIndexBNBMapping[tokenAddress];
        if(pairMapping[indexValue].addressTokenB==tokenAddress){
            helperSlipage(address(0),tokenAddress,msg.value,tokenAmount,minBNBAmount,minTokenAmount,false);
            TokenPair storage pairInfo=pairMapping[indexValue];
            pairInfo.lPoolTokens= pairInfo.lPoolTokens.add(LPTokens);
            pairInfo.amountTokenA=pairInfo.amountTokenA.add(msg.value);
            pairInfo.amountTokenB=pairInfo.amountTokenB.add(tokenAmount);
            userPairsMapping[msg.sender][indexValue].isAvailable=true;
            userPairsMapping[msg.sender][indexValue].lPoolTokens=
                                                (userPairsMapping[msg.sender][indexValue].lPoolTokens).add(LPTokens.sub(adminValue));
        }else{
             poolCount=poolCount.add(1);
             TokenPair memory pairInfo=TokenPair({
                amountTokenA:msg.value,
                amountTokenB:tokenAmount,
                lPoolTokens: LPTokens,
                addressTokenA:address(0),
                addressTokenB:tokenAddress
            });
            pairMapping[poolCount]=pairInfo;
            pairIndexBNBMapping[tokenAddress]=poolCount;
            UserPairs memory userPairInfo= UserPairs({
                isAvailable:true,
                lPoolTokens:LPTokens.sub(adminValue)
            });
            userPairsMapping[msg.sender][poolCount]=userPairInfo;
        }
        TransferHelper.safeTransferFrom(tokenAddress,msg.sender,address(this),tokenAmount);
        Token(poolTokenAddress).mint(msg.sender,LPTokens.sub(adminValue));
        Token(poolTokenAddress).mint(adminShareReceivingAddress,adminValue);
        userPairsMapping[adminShareReceivingAddress][poolCount].isAvailable=true;
        userPairsMapping[adminShareReceivingAddress][poolCount].lPoolTokens=userPairsMapping[adminShareReceivingAddress][poolCount].lPoolTokens.add(adminValue);
        emit addLiquidityEventBNBToToken(tokenAddress,adminShareReceivingAddress,msg.value,tokenAmount,block.timestamp, adminValue);
        emit addLiquidityEventBNBToToken(tokenAddress,msg.sender,msg.value,tokenAmount,block.timestamp,LPTokens.sub(adminValue));
    }
    
    function removeLiquidity(address tokenA, address tokenB, uint256 poolTokenAmount) external nonReentrant{
        helperMessagesTokens(poolTokenAddress,poolTokenAmount);
        if(tokenA==address(0)){
            removeLiquidityBNBFinal(tokenB,poolTokenAmount);
        }else if(tokenB==address(0)){
            removeLiquidityBNBFinal(tokenA,poolTokenAmount);
        }else{
            uint256 indexValue=pairIndexTokensMapping[tokenA][tokenB];
            TokenPair storage pairInfo=pairMapping[indexValue];
            require(userPairsMapping[msg.sender][indexValue].isAvailable,"This user has not provided the liquidity for this pair.");
            require(userPairsMapping[msg.sender][indexValue].lPoolTokens>=poolTokenAmount,"Cannot add more amount than your share in LP");
            uint256 percentage=(poolTokenAmount.mul(10**5)).div(pairInfo.lPoolTokens);
            uint256 tokenAAmountToBeGiven=(percentage.mul(pairInfo.amountTokenA)).div(10**5);
            uint256 tokenBAmountToBeGiven=(percentage.mul(pairInfo.amountTokenB)).div(10**5);
            if(pairInfo.addressTokenA==tokenA){
                TransferHelper.safeTransfer(tokenA,msg.sender,tokenAAmountToBeGiven);
                TransferHelper.safeTransfer(tokenB,msg.sender,tokenBAmountToBeGiven);
            }else{
                TransferHelper.safeTransfer(tokenA,msg.sender,tokenBAmountToBeGiven);
                TransferHelper.safeTransfer(tokenB,msg.sender,tokenAAmountToBeGiven);
            }
            TransferHelper.safeTransferFrom(poolTokenAddress,msg.sender,burnAddress,poolTokenAmount);
            pairInfo.amountTokenA=(pairInfo.amountTokenA).sub(tokenAAmountToBeGiven);
            pairInfo.amountTokenB=(pairInfo.amountTokenB).sub(tokenBAmountToBeGiven);
            pairInfo.lPoolTokens=(pairInfo.lPoolTokens).sub(poolTokenAmount);
            userPairsMapping[msg.sender][indexValue].lPoolTokens=(userPairsMapping[msg.sender][indexValue].lPoolTokens).sub(poolTokenAmount);
            if(userPairsMapping[msg.sender][indexValue].lPoolTokens==0){
                userPairsMapping[msg.sender][indexValue].isAvailable=false;
            }
            emit removeLiquidityEventTokenToToken(tokenA,tokenB,msg.sender,tokenAAmountToBeGiven, tokenBAmountToBeGiven, block.timestamp, poolTokenAmount);
            
        }
    }
    
    function removeLiquidityBNBFinal(address tokenAddress,uint256 _pooltokenAmount) internal{
        uint256 indexValue=pairIndexBNBMapping[tokenAddress];
        TokenPair storage pairInfo=pairMapping[indexValue];
        require(userPairsMapping[msg.sender][indexValue].isAvailable,"This user has not provided the liquidity for this pair.");
        require(userPairsMapping[msg.sender][indexValue].lPoolTokens>=_pooltokenAmount,"Cannot add more amount than your share in LP");
        uint256 percentage=(_pooltokenAmount.mul(10**5)).div(pairInfo.lPoolTokens);
        uint256 bnbAmountToBeGiven=(percentage.mul(pairInfo.amountTokenA)).div(10**5);
        uint256 tokenAmountToBeGiven=(percentage.mul(pairInfo.amountTokenB)).div(10**5);
        TransferHelper.safeTransferETH(msg.sender,bnbAmountToBeGiven);
        TransferHelper.safeTransfer(tokenAddress,msg.sender,tokenAmountToBeGiven);
        TransferHelper.safeTransferFrom(poolTokenAddress,msg.sender,burnAddress,_pooltokenAmount);
        pairInfo.amountTokenA=(pairInfo.amountTokenA).sub(bnbAmountToBeGiven);
        pairInfo.amountTokenB=(pairInfo.amountTokenB).sub(tokenAmountToBeGiven);
        pairInfo.lPoolTokens=(pairInfo.lPoolTokens).sub(_pooltokenAmount);
        userPairsMapping[msg.sender][indexValue].lPoolTokens=(userPairsMapping[msg.sender][indexValue].lPoolTokens).sub(_pooltokenAmount);
        if(userPairsMapping[msg.sender][indexValue].lPoolTokens==0){
            userPairsMapping[msg.sender][indexValue].isAvailable=false;
        }
        emit removeLiquidityEventBNBToToken(tokenAddress,msg.sender,bnbAmountToBeGiven,tokenAmountToBeGiven,block.timestamp,_pooltokenAmount);
    }
    
    function swap(address fromTokenA, address toTokenB, uint256 _amountTokenA,uint256 _amountTokenB, 
                    uint256 _minAmountA, uint256 _minAmountB) external payable nonReentrant{
        if(fromTokenA==address(0)){
            uint256 indexValue=pairIndexBNBMapping[toTokenB];
            TokenPair storage pairInfo=pairMapping[indexValue];
            require(pairInfo.amountTokenA>0,"No Liquidity Found.");
            uint256 swapAmount=helperSlipage(fromTokenA,toTokenB,msg.value,_amountTokenB,_minAmountA,_minAmountB,true);
            require((pairInfo.amountTokenB)>=swapAmount,"Not enough LP");
            TransferHelper.safeTransfer(toTokenB,msg.sender,swapAmount);
            pairInfo.amountTokenA=pairInfo.amountTokenA.add(msg.value);
            pairInfo.amountTokenB=pairInfo.amountTokenB.sub(swapAmount);
            emit swapEvent(fromTokenA,toTokenB,pairInfo.amountTokenA, pairInfo.amountTokenB);
        }else if(toTokenB==address(0)){
            helperMessagesTokens(fromTokenA,_amountTokenA);
            uint256 indexValue=pairIndexBNBMapping[fromTokenA];
            TokenPair storage pairInfo=pairMapping[indexValue];
            require(pairInfo.amountTokenB>0,"No Liquidity Found.");
            uint256 swapAmount=helperSlipage(fromTokenA,toTokenB,_amountTokenA,msg.value,_minAmountA,_minAmountB,true);
            require((pairInfo.amountTokenA)>=swapAmount,"Not enough LP");
            TransferHelper.safeTransferFrom(fromTokenA,msg.sender,address(this),_amountTokenA);
            TransferHelper.safeTransferETH(msg.sender,swapAmount);
            pairInfo.amountTokenA=pairInfo.amountTokenA.sub(swapAmount);
            pairInfo.amountTokenB=pairInfo.amountTokenB.add(_amountTokenA);
            emit swapEvent(fromTokenA,toTokenB,pairInfo.amountTokenA, pairInfo.amountTokenB);
        }else{
            helperMessagesTokens(fromTokenA,_amountTokenA);
            uint256 indexValue=pairIndexTokensMapping[fromTokenA][toTokenB];
            TokenPair storage pairInfo=pairMapping[indexValue];
            if(pairInfo.addressTokenA==fromTokenA){
                require(pairInfo.amountTokenA>0,"No Liquidity Found.");
                uint256 swapAmount=helperSlipage(fromTokenA,toTokenB,_amountTokenA,_amountTokenB,_minAmountA,_minAmountB,true);
                require((pairInfo.amountTokenB)>=swapAmount,"Not enough LP");
                TransferHelper.safeTransfer(toTokenB,msg.sender,swapAmount);
                TransferHelper.safeTransferFrom(fromTokenA,msg.sender,address(this),_amountTokenA);
                pairInfo.amountTokenA=pairInfo.amountTokenA.add(_amountTokenA);
                pairInfo.amountTokenB=pairInfo.amountTokenB.sub(swapAmount);
            }else{
                require(pairInfo.amountTokenB>0,"No Liquidity Found.");
                uint256 swapAmount=helperSlipage(fromTokenA,toTokenB,_amountTokenA,_amountTokenB,_minAmountA,_minAmountB,true);
                TransferHelper.safeTransfer(toTokenB,msg.sender,swapAmount);
                TransferHelper.safeTransferFrom(fromTokenA,msg.sender,address(this),_amountTokenA);
                pairInfo.amountTokenA=pairInfo.amountTokenA.sub(swapAmount);
                pairInfo.amountTokenB=pairInfo.amountTokenB.add(_amountTokenA);
            }
            emit swapEvent(fromTokenA,toTokenB,pairInfo.amountTokenA, pairInfo.amountTokenB);
        }
        
    }
    
    function helperSlipage(address fromTokenA, address toTokenB, 
                            uint256 _amountTokenA, uint256 _amountTokenB, 
                            uint256 _minAmountA, uint256 _minAmountB,
                            bool includeFee) internal view returns(uint256){
        (,uint256 swapAmount)=getAmountOut(fromTokenA,toTokenB,_amountTokenA,includeFee);
        require(swapAmount>=_minAmountB,"Insufficient Amount.");
        (,uint256 swapTokenAmount)=getAmountOut(toTokenB,fromTokenA,_amountTokenB,includeFee);
        require(swapTokenAmount>=_minAmountA,"Insufficient Amount.");
        return swapAmount;
    }
    
    function getAmountOut(address fromTokenA, address toTokenB, uint256 _amountTokenA, bool includeFee) public view returns(uint256,uint256){
        uint256 amountOut;
        uint256 amountIn=(includeFee?(_amountTokenA.sub((swappingFee.mul(_amountTokenA)).div(10**5))):(_amountTokenA));
        if(fromTokenA==address(0)){
            uint256 indexValue=pairIndexBNBMapping[toTokenB];
            TokenPair memory pairInfo=pairMapping[indexValue];
            amountOut=messageOut(includeFee,pairInfo.amountTokenA,pairInfo.amountTokenB,amountIn);
        }else if(toTokenB==address(0)){
            uint256 indexValue=pairIndexBNBMapping[fromTokenA];
            TokenPair memory pairInfo=pairMapping[indexValue];
            amountOut=messageOut(includeFee,pairInfo.amountTokenB,pairInfo.amountTokenA,amountIn);
        }else{
            uint256 indexValue=pairIndexTokensMapping[fromTokenA][toTokenB];
            TokenPair memory pairInfo=pairMapping[indexValue];
            if(pairInfo.addressTokenA==fromTokenA){
                amountOut=messageOut(includeFee,pairInfo.amountTokenA,pairInfo.amountTokenB,amountIn);
            }else{
                amountOut=messageOut(includeFee,pairInfo.amountTokenB,pairInfo.amountTokenA,amountIn);
            }
        }
        return (amountIn,amountOut);
    }
    
    function messageOut(bool _includeFee, uint256 _amountTokenA, uint256 _amountTokenB, uint256 amountIn) internal pure returns(uint256){
        if(_includeFee){
            require(_amountTokenA>0,"No Liquidity Found.");
        }
        uint256 amountOut= (((_amountTokenB).mul(amountIn))
                                        .div(_amountTokenA));
        if(_includeFee){
            require((_amountTokenB)>=amountOut,"Not enough LP");
        }
        return amountOut;
    }
    function messageSwapOut(uint256 _amountTokenA, uint256 _amountTokenB, uint256 amountIn) internal pure returns(uint256){
        require(_amountTokenA>0,"No Liquidity Found.");
        uint256 swapAmount=((_amountTokenB).mul(amountIn))
                                        .div(_amountTokenA);
        require((_amountTokenB)>=swapAmount,"Not enough LP");
        return swapAmount;
    }
    function swapByRoute(address fromTokenA, address byRouteTokenB, address toTokenC, uint256 _amountTokenA) external payable nonReentrant{
        if(fromTokenA==address(0)){
            require(msg.value>=0,"Please enter value greater than 0.");
            uint256 bnbAmountOut=msg.value.sub((swappingFee.mul(msg.value)).div(10**5));
            uint256 indexValueB=pairIndexBNBMapping[byRouteTokenB];
            TokenPair storage pairInfoB=pairMapping[indexValueB];
            uint256 swapAmountTokenB=messageSwapOut(pairInfoB.amountTokenA,pairInfoB.amountTokenB,bnbAmountOut);
            pairInfoB.amountTokenA=pairInfoB.amountTokenA.add(msg.value);
            pairInfoB.amountTokenB=pairInfoB.amountTokenB.sub(swapAmountTokenB);
            uint256 indexValueTwo=pairIndexTokensMapping[byRouteTokenB][toTokenC];
            TokenPair storage pairInfoTwo=pairMapping[indexValueTwo];
            emit swapEvent(fromTokenA,byRouteTokenB,pairInfoB.amountTokenA, pairInfoB.amountTokenB);
            if(pairInfoTwo.addressTokenA==byRouteTokenB){
                uint256 swapAmount=messageSwapOut(pairInfoTwo.amountTokenA,pairInfoTwo.amountTokenB,swapAmountTokenB);
                TransferHelper.safeTransfer(toTokenC,msg.sender,swapAmount);
                pairInfoTwo.amountTokenA=pairInfoTwo.amountTokenA.add(swapAmountTokenB);
                pairInfoTwo.amountTokenB=pairInfoTwo.amountTokenB.sub(swapAmount);
                emit swapEvent(byRouteTokenB,toTokenC,pairInfoTwo.amountTokenA, pairInfoTwo.amountTokenB);
            }else{
                uint256 swapAmount=messageSwapOut(pairInfoTwo.amountTokenB,pairInfoTwo.amountTokenA,swapAmountTokenB);
                TransferHelper.safeTransfer(toTokenC,msg.sender,swapAmount);
                pairInfoTwo.amountTokenA=pairInfoTwo.amountTokenA.sub(swapAmount);
                pairInfoTwo.amountTokenB=pairInfoTwo.amountTokenB.add(swapAmountTokenB);
                emit swapEvent(byRouteTokenB,toTokenC,pairInfoTwo.amountTokenB, pairInfoTwo.amountTokenA);
            }
        }else if(byRouteTokenB==address(0)){
            helperMessagesTokens(fromTokenA,_amountTokenA);
            uint256 tokenAmountOut=_amountTokenA.sub((swappingFee.mul(_amountTokenA)).div(10**5));
            uint256 indexValueA=pairIndexBNBMapping[fromTokenA];
            TokenPair storage pairInfoA=pairMapping[indexValueA];
            uint256 swapAmountBNB=messageSwapOut(pairInfoA.amountTokenB,pairInfoA.amountTokenA,tokenAmountOut);
            pairInfoA.amountTokenA=pairInfoA.amountTokenA.sub(swapAmountBNB);
            pairInfoA.amountTokenB=pairInfoA.amountTokenB.add(_amountTokenA);
            uint256 indexValueC=pairIndexBNBMapping[toTokenC];
            TokenPair storage pairInfoC=pairMapping[indexValueC];
            uint256 swapAmountToken=messageSwapOut(pairInfoC.amountTokenA,pairInfoC.amountTokenB,swapAmountBNB);
            TransferHelper.safeTransferFrom(fromTokenA,msg.sender,address(this),_amountTokenA);
            TransferHelper.safeTransfer(toTokenC,msg.sender,swapAmountToken);
            pairInfoC.amountTokenA=pairInfoC.amountTokenA.add(swapAmountBNB);
            pairInfoC.amountTokenB=pairInfoC.amountTokenB.sub(swapAmountToken);
            emit swapEvent(fromTokenA,byRouteTokenB,pairInfoA.amountTokenB, pairInfoA.amountTokenA);
            emit swapEvent(byRouteTokenB,toTokenC,pairInfoC.amountTokenA, pairInfoC.amountTokenB);
        }else if(toTokenC==address(0)){
            helperMessagesTokens(fromTokenA,_amountTokenA);
            uint256 tokenAmountOut=_amountTokenA.sub((swappingFee.mul(_amountTokenA)).div(10**5));
            uint256 swapAmountTokenB;
            uint256 indexValueTwo=pairIndexTokensMapping[fromTokenA][byRouteTokenB];
            TokenPair storage pairInfoTwo=pairMapping[indexValueTwo];
             if(pairInfoTwo.addressTokenA==fromTokenA){
                swapAmountTokenB=messageSwapOut(pairInfoTwo.amountTokenA,pairInfoTwo.amountTokenB,tokenAmountOut);
                pairInfoTwo.amountTokenA=pairInfoTwo.amountTokenA.add(_amountTokenA);
                pairInfoTwo.amountTokenB=pairInfoTwo.amountTokenB.sub(swapAmountTokenB);
                emit swapEvent(fromTokenA,byRouteTokenB,pairInfoTwo.amountTokenA, pairInfoTwo.amountTokenB);
               
            }else{
                swapAmountTokenB=messageSwapOut(pairInfoTwo.amountTokenB,pairInfoTwo.amountTokenA,tokenAmountOut);
                pairInfoTwo.amountTokenA=pairInfoTwo.amountTokenA.sub(swapAmountTokenB);
                pairInfoTwo.amountTokenB=pairInfoTwo.amountTokenB.add(_amountTokenA);
                emit swapEvent(fromTokenA,byRouteTokenB,pairInfoTwo.amountTokenB, pairInfoTwo.amountTokenA);
            }
            uint256 indexValueB=pairIndexBNBMapping[byRouteTokenB];
            TokenPair storage pairInfoB=pairMapping[indexValueB];
            uint256 swapAmountBNB=messageSwapOut(pairInfoB.amountTokenB,pairInfoB.amountTokenA,swapAmountTokenB);
            TransferHelper.safeTransferFrom(fromTokenA,msg.sender,address(this),_amountTokenA);
            TransferHelper.safeTransferETH(msg.sender,swapAmountBNB);
            pairInfoB.amountTokenA=pairInfoB.amountTokenA.sub(swapAmountBNB);
            pairInfoB.amountTokenB=pairInfoB.amountTokenB.add(swapAmountTokenB);
            emit swapEvent(byRouteTokenB,toTokenC,pairInfoB.amountTokenB, pairInfoB.amountTokenA);
        }else{
            helperMessagesTokens(fromTokenA,_amountTokenA);
            uint256 tokenAmountOut=_amountTokenA.sub((swappingFee.mul(_amountTokenA)).div(10**5));
            uint256 swapAmountTokenB;
            uint256 indexValueTwo=pairIndexTokensMapping[fromTokenA][byRouteTokenB];
            TokenPair storage pairInfoTwo=pairMapping[indexValueTwo];
             if(pairInfoTwo.addressTokenA==fromTokenA){
                swapAmountTokenB=messageSwapOut(pairInfoTwo.amountTokenA,pairInfoTwo.amountTokenB,tokenAmountOut);
                pairInfoTwo.amountTokenA=pairInfoTwo.amountTokenA.add(_amountTokenA);
                pairInfoTwo.amountTokenB=pairInfoTwo.amountTokenB.sub(swapAmountTokenB);
                emit swapEvent(fromTokenA,byRouteTokenB,pairInfoTwo.amountTokenA, pairInfoTwo.amountTokenB);
               
            }else{
                swapAmountTokenB=messageSwapOut(pairInfoTwo.amountTokenB,pairInfoTwo.amountTokenA,tokenAmountOut);
                pairInfoTwo.amountTokenA=pairInfoTwo.amountTokenA.sub(swapAmountTokenB);
                pairInfoTwo.amountTokenB=pairInfoTwo.amountTokenB.add(_amountTokenA);
                emit swapEvent(fromTokenA,byRouteTokenB,pairInfoTwo.amountTokenB, pairInfoTwo.amountTokenA);
            }
            uint256 indexValueTwoA=pairIndexTokensMapping[byRouteTokenB][toTokenC];
            TokenPair storage pairInfoTwoA=pairMapping[indexValueTwoA];
            if(pairInfoTwoA.addressTokenA==byRouteTokenB){
                uint256 swapAmountTokenC=messageSwapOut(pairInfoTwoA.amountTokenA,pairInfoTwoA.amountTokenB,swapAmountTokenB);
                TransferHelper.safeTransferFrom(fromTokenA,msg.sender,address(this),_amountTokenA);
                TransferHelper.safeTransfer(toTokenC,msg.sender,swapAmountTokenC);
                pairInfoTwoA.amountTokenA=pairInfoTwoA.amountTokenA.add(swapAmountTokenB);
                pairInfoTwoA.amountTokenB=pairInfoTwoA.amountTokenB.sub(swapAmountTokenC);
                emit swapEvent(byRouteTokenB,toTokenC,pairInfoTwoA.amountTokenA, pairInfoTwoA.amountTokenB);
            }else{
                uint256 swapAmountTokenC=messageSwapOut(pairInfoTwoA.amountTokenB,pairInfoTwoA.amountTokenA,swapAmountTokenB);
                TransferHelper.safeTransferFrom(fromTokenA,msg.sender,address(this),_amountTokenA);
                TransferHelper.safeTransfer(toTokenC,msg.sender,swapAmountTokenC);
                pairInfoTwoA.amountTokenA=pairInfoTwoA.amountTokenA.sub(swapAmountTokenC);
                pairInfoTwoA.amountTokenB=pairInfoTwoA.amountTokenB.add(swapAmountTokenB);
                emit swapEvent(byRouteTokenB,toTokenC,pairInfoTwoA.amountTokenB, pairInfoTwoA.amountTokenA);
            }
        }
    }
    
    function helperMessagesTokens(address _token, uint256 _amountToken) internal view returns(bool){
        require((Token(_token).balanceOf(msg.sender))>=_amountToken,"Please check balance in your account.");
        require((Token(_token).allowance(msg.sender, address(this)))>=_amountToken,"Please check approvals.");
        return false;
    }
    
    function updateSwapFee(uint256 _swappingFee) external onlyOwner{
        swappingFee=_swappingFee;
    }
    function updateAdminShareReceivingAddress(address _adminShareReceivingAddress) external onlyOwner{
        adminShareReceivingAddress=_adminShareReceivingAddress;
    }
    function updateAdminShare(uint256 _adminShare) external onlyOwner{
        adminShare=_adminShare;
    }
    function updateBurnAddress(address _burnAddress) external onlyOwner{
        burnAddress=_burnAddress;
    }
    
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}