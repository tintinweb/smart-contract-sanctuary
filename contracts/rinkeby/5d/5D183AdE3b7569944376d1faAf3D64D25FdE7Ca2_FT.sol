// SPDX-License-Identifier: MIT
 pragma solidity >=0.6.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
 
//import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC721/IERC721.sol";
//import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC20/IERC20.sol";
//import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "@openzeppelin/contracts/access/AccessControl.sol";
//import '@uniswap/lib/contracts/libraries/FixedPoint.sol';
//import "./ICore.sol";


/**
* Interfaces
*     
    //IBancorFormula Rinkeby : 0xDA4d32A96a3D765d58BBf3940affcCcDcc777D9b
    //WETH Rinkeby:  0xc778417E063141139Fce010982780140Aa0cD5Ab
    //UniswapV2Factory Rinkeby : 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    //UniswapV2Router2 Rinkeby : 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    //IFusefactory Rinkeby : 0x1102Bd416CB31Bca681b9f2BB896155895f97428
    //IUniswapPair Rinkeby: 
**/

interface IFTfactory {
    event newNFTtoERC20Mint(address indexed fuserc20Contract, address indexed mintedBy);
    function createFuseERC20(uint256 _supply,address _NFTAddr, uint256 _tokenId, address _nftOwner) external returns(address);
    function ownerOfERC20(address _erc20Address) view external returns(address);
}
interface IFToken{
    function burn(uint256 _tknAmt) external returns(bool);
    function setValuePerShare(uint _vps,uint _rem) external payable  returns(bool);
    function nftIdtoRec(address _nft,uint _tknId) external view returns(bytes32);
    function initUniLPwithETH(bytes32 _receiptId,uint _amountTokenDesired,
    uint32 _rRatio,uint256 _maxCap,bool _rRtype) external  payable returns (uint amountToken, uint amountETH, uint liquidity);
}
interface IUniswapPair{
    function kLast() external view returns (uint);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
}
interface IUniswapFactory{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Route2{
    
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
    ) external returns (uint amountA, uint amountB, uint liquidity);
    
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external payable
      returns (uint[] memory amounts);
}
interface IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _reserveBalance, uint32 _reserveRatio, uint256 _depositAmount) external view returns (uint256);
}
interface IFUSIINFT{

        function getNFTDetails(uint256 tokenId) external view returns(address[] memory owners,uint8 royalty, uint8[] memory splits,uint8 editions,uint8 editionNum);
    
}
contract FT is  ERC20,AccessControl {
       using SafeMath for uint256;
    /**
    * Event logs
    */
    event Received(uint256 _ether,address _from);
    
    event NFTLockedAndERCMinted(
        bytes32 indexed receiptId,
        address indexed ownedBy,
        address indexed mintedERC20,
        address tokenContract,
        uint256 tokenId
    );
    event InitLPSeeded(
        bytes32 indexed receiptId,
        uint pricePerToken, uint  poolBalanceReserve, uint  liquidityAtUniswap

    );
    /**
    *State Setup  */

    /**
    * Structs 
     */

    struct LockReceipt {
        address seller;
        address mintedERC20Addr;
        address NFTContract;
        bool fusiiNFT;
        bool tradable;
        uint256 tokenId;
        //address pair;
        //address token0;
    }

    struct CurveRules{
        
        uint256 poolBalanceReserve;
        uint256 initUNITokens;
        uint256 initUNIETH;
        uint32 rRatio; //PPM
        uint256 lastPrice;
        uint256 totalSupply;
        uint256 floorPrice;
        uint256 maxCap; //Max cap per user.
        bool rRatioType; //true:expo (dynamic) rRatio,false: linear(fixed | linear) rRatio,
        uint256 dustBalance;
    }
    /*
    * Mappings
    */
    mapping (address => CurveRules) curveParameters;
    mapping (bytes32 => LockReceipt) receipts;
    mapping (address => mapping(uint => bytes32)) public nftIdtoRec;
    
    //Exit Rules?
    /**
    * Modifiers */
    modifier tokensTransferable(address _token, uint256 _tokenId) {
        // ensure this contract is approved to transfer the designated token
        // so that it is able to honor the claim request later
        require(
            IERC721(_token).getApproved(_tokenId) == address(this),
            "Approve: TokenId against Fusible Contract"
        );
        _;
    }
    modifier receiptExist(bytes32 _receiptId){
        require(haveReceipt(_receiptId),"Receipt not found");
        _;
    }
    modifier onlyReceiptOwner(bytes32 _receiptId){
        require(receipts[_receiptId].seller==msg.sender,"Not a receiptOwner");
        _;
    }
    
    address public nftAddr;
    uint256 public tokenId;
    uint256 public valuePerFT;
    uint256 public rem;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    event RecoverToken(address indexed token, address indexed destination, uint256 indexed amount);
    
    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender),"Not Operator");
        _;
    }
     /*
     *
     * State variable
        //IBancorFormula Rinkeby : 0xDA4d32A96a3D765d58BBf3940affcCcDcc777D9b
     */
     address private BF = 0xDA4d32A96a3D765d58BBf3940affcCcDcc777D9b;
     address private AMM_FACTORY=0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
     address private _treasury=0xAC55e1B40436eC486b02a9F2E87F72cCfbbDd05B;
     address private AMM_ROUTEV2=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 
     address private FUSIINFT =0xe496e6817fe4E7587ACbBD0083F7d2E0A9f4C3A1;
     uint private _pFee=10000;
     uint private _AMM_LPP=250000;
     bool private once = true;
     address pair;


    constructor(uint256 _supply,address _NFTAddr, uint256 _tokenId) ERC20("Fusible V0", "FT V0") {
        nftAddr = _NFTAddr;
        tokenId = _tokenId;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE,_msgSender());
        _mint(address(this), _supply);
         bytes32 receiptId = sha256( abi.encodePacked(_msgSender(),_NFTAddr,_tokenId,block.timestamp));// Replace this with the FT address.
        nftIdtoRec[_NFTAddr][_tokenId]= receiptId;
        receipts[receiptId] = LockReceipt( 
            msg.sender,
            address(this),
            _NFTAddr,
            (_NFTAddr==FUSIINFT)?true: false,
            false,
            _tokenId
        );

        emit NFTLockedAndERCMinted(
            receiptId,
            tx.origin,
            address(this),
            _NFTAddr,
            _tokenId
        );
    }




    function burn(uint256 _tknAmt) internal onlyOperator returns(bool) {
        require(_tknAmt > 0,"Check token Balance or input amount");
        _burn(msg.sender,_tknAmt);
        return true;
        
    }

    function setValuePerShare(uint _vps,uint _rem) external payable onlyOperator returns(bool){
        valuePerFT = _vps;
        rem=_rem;
        return(true);
    }

    function burnMyFT() public {
        require(valuePerFT>0,"NFT isn't sold yet");
        uint256 balFToken=IERC20(address(this)).balanceOf(_msgSender());
        require(address(this).balance>=balFToken.mul(valuePerFT).div(10**18),"Not enough balance");
        _burn(_msgSender(),balFToken);
        safeTransferETH(_msgSender(), valuePerFT.mul(balFToken).div(10**18));

    }
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }

    
      /**
     * @notice Function to recover funds
     * Owner is assumed to be governance or Fusi trusted party for helping users
     * @param token Address of token to be rescued
     * @param destination User address
     * @param amount Amount of tokens
     */
    function recoverToken(
        address token,
        address destination,
        uint256 amount
    ) external onlyOperator {
        require(token != destination, "Invalid address");
        require(IERC20(token).transfer(destination, amount), "Retrieve failed");
        emit RecoverToken(token, destination, amount);
    }
    function initUniLPwithETH(bytes32 _receiptId,uint _amountTokenDesired,
    uint32 _rRatio,uint256 _maxCap,bool _rRtype
    ) 
    onlyReceiptOwner(_receiptId) receiptExist(_receiptId) 
       external   payable returns (uint tokenAmount, uint amountETH, uint liquidity){
           
        require(IERC20(address(this)).approve(AMM_ROUTEV2, type(uint256).max-1),"Token must be approved");//only uint256
        require(once,"Has to be initiated only once");
        require(msg.value > 0 && _amountTokenDesired > 0,"Input value should be > 0  ");
        require(_rRatio>0 && _rRatio<=1000000);
        address _erc20Token = receipts[_receiptId].mintedERC20Addr;
        
        pair = IUniswapFactory(AMM_FACTORY).createPair(address(this),0xc778417E063141139Fce010982780140Aa0cD5Ab);
        //require(approveTokensForInitLPSeed(_erc20Token),"Approve Minted Erc20 Tokens for LP");
        //External Contract to approve and erc20minted token
        
        ( tokenAmount,  amountETH,  liquidity) = addUniswapLP(_erc20Token,_amountTokenDesired,msg.value);
        uint256 lastPrice = (msg.value).mul(1000000).div(tokenAmount);
        uint floor = lastPrice.mul(IERC20(_erc20Token).totalSupply()).div(10**6);
        lastPrice = lastPrice.mul(10**18).div(10**6);
        curveParameters[_erc20Token] = CurveRules(msg.value,_amountTokenDesired,msg.value,_rRatio,lastPrice,(IERC20(_erc20Token).totalSupply()),floor,_maxCap,_rRtype,0);
        once = false;

     emit InitLPSeeded (_receiptId,tokenAmount, amountETH, liquidity);

    }
     
    /**Step 4: BuyToken & addLiquidity to the UNI or Swap ETH/Token at UNI TODO restructure add conditional statements
     * Add Condition for fixed price, linear and exponential price
     */
    function buyMintedTokens(bytes32 _receiptId) receiptExist(_receiptId)  external payable returns(uint256 ft){
        require(msg.value>0,"Enter ETH amount");
        address seller= receipts[_receiptId].seller;
        address _erc20Token = receipts[_receiptId].mintedERC20Addr;
        require(IERC20(_erc20Token).balanceOf(address(this))>0,"Low balance");
        CurveRules storage c = curveParameters[_erc20Token];
        require(c.poolBalanceReserve != 0,"Init poolBalanceReserve");
        //Route to IBancorFormula 
        //uint _amtTransfer = IBancorFormula(0xDA4d32A96a3D765d58BBf3940affcCcDcc777D9b).calculatePurchaseReturn(c.totalSupply,c.poolBalanceReserve,c.rRatio,msg.value);
        uint _amtTransfer = computeFTperETH(c.totalSupply,c.poolBalanceReserve,c.rRatio,msg.value);
        if(_amtTransfer >= IERC20(_erc20Token).balanceOf(address(this)))
            _amtTransfer = IERC20(_erc20Token).balanceOf(address(this));
        c.poolBalanceReserve = c.poolBalanceReserve.add(msg.value);
        IERC20(_erc20Token).transfer(msg.sender,_amtTransfer);
        //last price => X ETH give Y tokens; 1 token = X/Y 
        c.lastPrice = (msg.value).mul(1000000).div(_amtTransfer);
        c.lastPrice = c.lastPrice.mul(10**18).div(10**6);
        //Transfer Fee
        // address pOAddr = 0xAC55e1B40436eC486b02a9F2E87F72cCfbbDd05B;//CONST
         uint256 platformFee = computeFeePPM(msg.value,_pFee);//2%
         uint256 UNILP = computeFeePPM(msg.value,_AMM_LPP);//25%

        uint256 _amountTokenDesired = computeQuote(UNILP,_erc20Token,!(_erc20Token>0xc778417E063141139Fce010982780140Aa0cD5Ab));
        //Provide LP to UNI 25%
        if(_amountTokenDesired > 0){
           (,uint256 _eAmt,)=addUniswapLP(_erc20Token,_amountTokenDesired,UNILP);
            if(_eAmt <= UNILP)
                c.dustBalance = c.dustBalance.add(UNILP.sub(_eAmt));
        }
        else
            UNILP=0;
        uint256 sellerShare = msg.value - (UNILP.add(platformFee));
        //send if _amountTokenDesired 0, 99% else 66% to seller
        safeTransferETH(seller, sellerShare);
        //send 1% to platform
        safeTransferETH(_treasury, platformFee);

        //require(successSeller && successPlatform,"Transfer Failed");
        ft = sellerShare;
    }
    /**Step 5: Exit, IFF X+Y+Z = 95% in PPM of totalSupply then Exit 
    function exit(bytes32 _receiptId) receiptExist(_receiptId) public payable {
        uint256 userTokenBal;
        address _erc20Token = receipts[_receiptId].mintedERC20Addr;
        
        (uint _eth,uint _tokens,uint liquidity, bool _xyFlag) = getRedeemingValues(_erc20Token);
        
        
        require(msg.value == _eth,"Insufficent amount");
        //RemoveLiquidity, burn & transfer Eth to seller and nft to buyer
        //uint256 allowance = token.allowance(msg.sender, address(this));
        //require(allowance >= amount, "Staking: Token allowance too small");
        if(_tokens > 0){

        userTokenBal = getBalance(_erc20Token,msg.sender);
        require(userTokenBal >= _tokens,"Insufficent tokens");
        IERC20(_erc20Token).transferFrom(msg.sender, address(this), userTokenBal);
        }
        
        //unlocktoken, reset receipt address And transfer NFT
        (, uint amountETH)=removeUniswapLP( _erc20Token,  liquidity);
        uint amountToBurn= getBalance(_erc20Token,address(this));
        require(burnERC20Token( _erc20Token, amountToBurn),"Burning failed check burnol amount!");
        //compute the ETH to be sent to seller
        amountETH = amountETH.add(curveParameters[_erc20Token].dustBalance);
        require(address(this).balance >= amountETH,"Insufficent coreETHBal");
        amountETH = amountETH.add(msg.value);
        

        //if not xy == totalSupply, 5% cut of amountETH < Exact swap with FUSI token on uniswap and send it to  > 
        if(!_xyFlag){
            uint256 assuranceFund = computeFeePPM(amountETH,50000);
            //Make call to External contract fixing burn per token. 1 erc20 token = y FUSI
        require(swapForFusii( assuranceFund,0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735),"Swap assuranceFund");
        
        //Dai 0xc7ad46e0b8a400bb3c915120d284aafba8fc4735
        amountETH = amountETH.sub(assuranceFund);
        
        }
        safeTransferETH(receipts[_receiptId].seller,amountETH);
        require(unlockAndWithdrawNFT( _receiptId,  msg.sender),"Unable to transfer");
        
        
    }*/

    function exit(bytes32 _receiptId) receiptExist(_receiptId) public payable {
        address _erc20Token = receipts[_receiptId].mintedERC20Addr;
        address seller = receipts[_receiptId].seller;
        
        (uint _eth,,uint liquidity, bool _xyFlag) = getRedeemingValues(_erc20Token);
        //1 ETH

        require(msg.value == _eth,"Insufficent amount");
        //Deduct 2.5% fee and royalty 
        //<Code here>
        uint256 pFee = computeFeePPM(_eth, _pFee);
        
        if(receipts[_receiptId].fusiiNFT){
            (address[] memory owners,uint8 royalty, uint8[] memory splits,,)= IFUSIINFT(FUSIINFT).getNFTDetails(receipts[_receiptId].tokenId);
           uint256 r = uint256(royalty);
           r = r.mul(10000);
           r = computeFeePPM(_eth, r);
           for(uint i = 0;i< owners.length;i++){
               uint256 ors = uint256(splits[i]);
               ors = ors.mul(10000);
               ors = computeFeePPM(r, ors);
               safeTransferETH(owners[i], ors);
           }
            _eth=_eth.sub(r);
           
        }
        _eth=_eth.sub(pFee);

        
        // replace _eth with remaining eth
        uint valuePerFT = _eth.mul(10**6).div(curveParameters[_erc20Token].totalSupply.div(10**18));
        //1/1000 = 0.001
        valuePerFT = valuePerFT.div(10**6); 
        //unlocktoken, reset receipt address And transfer NFT
        
        (, uint sellerAmountETH)=removeUniswapLP( _erc20Token,  liquidity);
        //sAE = 0.5, 500
        uint amountToBurn= getBalance(_erc20Token,address(this));//1000
        uint remainingFT = curveParameters[_erc20Token].totalSupply.sub(amountToBurn);//0
       
        //require(burnERC20Token( _erc20Token, amountToBurn),"Burning failed check burnol amount!");
        //compute the ETH to be sent to seller
        sellerAmountETH = sellerAmountETH.add(curveParameters[_erc20Token].dustBalance);//Add dust 0.5+0
        uint256 sellerGains = amountToBurn.mul(valuePerFT).div(10**18);//1000*0.001=1
        uint remainingETH = remainingFT.mul(valuePerFT).div(10**18);
        sellerAmountETH = sellerAmountETH.add(sellerGains); //Add FT holdings of the seller. sAE = 1+0.5= 1.5

        require(address(this).balance >= sellerAmountETH,"Insufficent coreETHBal");
        uint256 amountETHForFT = _eth.sub(sellerGains);
        //require(remainingETH == amountETHForFT,"Must be equal");
        require(_eth >= remainingETH.add(sellerGains));
        //require(amountETHForFT == valuePerFT.mul(remainingFT),"Not Equal damn it");
        require(burnERC20Token( _erc20Token, amountToBurn),"Burning failed check burnol amount!");
        //Transfer Amount to Seller
        safeTransferETH(seller,sellerAmountETH);
        //Transfer pFee to treasury
        safeTransferETH(_treasury,pFee);
        //Transfer if remaining
        if(!(_xyFlag) && remainingFT>0){
            IFToken(_erc20Token).setValuePerShare{value:remainingETH}(valuePerFT,remainingFT);
           // safeTransferETH(_erc20Token,amountETHForFT );
        }
        require(unlockAndWithdrawNFT( _receiptId,  msg.sender),"Unable to transfer");


    }
    function testvaluePerFT(uint256 amtIn,address _erc20Token)public view returns(uint256 valuePerFT,uint256 amountToBurn,uint256 sellerGains){

         valuePerFT = amtIn.mul(10**6).div(curveParameters[_erc20Token].totalSupply.div(10**18));
         valuePerFT = valuePerFT.div(10**6);
         amountToBurn= getBalance(_erc20Token,address(this));
         sellerGains = amountToBurn.mul(valuePerFT).div(10**18);

    }
    
    function getRedeemingValues(address _erc20Token)  public view returns(uint ethValue,uint tokens,uint liquidity, bool xyFlag) {

        (uint256 _xyValue,,,uint256 _liquidity) = computeXY(_erc20Token,address(this));
        
        //require(_xyValue < curveParameters[_erc20Token].totalSupply,"XY should be less then totalSupply" );
        uint256 minimaTotalSupply =  computeFeePPM(curveParameters[_erc20Token].totalSupply,990000);
        //require(getBalance(_erc20Token,msg.sender).add(_xyValue) >= minimaTotalSupply,"");
        //X+Y == totalSupply; Pay
        if(_xyValue ==  curveParameters[_erc20Token].totalSupply || _xyValue >= minimaTotalSupply){
            (_xyValue ==  curveParameters[_erc20Token].totalSupply)?xyFlag = true:xyFlag = false;
        
            tokens = 0; }
        else if(minimaTotalSupply > _xyValue)
            tokens = minimaTotalSupply.sub(_xyValue);
        //Compute price per token
        ethValue = computeQuote(10**18,_erc20Token,(_erc20Token>0xc778417E063141139Fce010982780140Aa0cD5Ab));
        ethValue = ethValue.add(curveParameters[_erc20Token].lastPrice).div(2);
        //ethValue, here
        ethValue=ethValue.mul(curveParameters[_erc20Token].totalSupply);
        if(ethValue < (curveParameters[_erc20Token].floorPrice))
            ethValue = curveParameters[_erc20Token].floorPrice;
        
        //require(burnERC20Token(_erc20Token,_x),"Successfully burnt"); //Please deelete this code after testing
        return(ethValue.div(10**18),tokens,_liquidity,xyFlag);
    
            
        //X+Y
        //Burn X balance, RemoveLiquidity and Burn Y value;
        //Currently it takes the overall balance of Token. Either add  per mint and cross check.        
    }
    //
    function computeXY(address _token,address _holderX) public  view returns(uint256,uint,uint,uint){
        address _holderY = getPairAddress(_token);// UNI cont address
        uint256 _x = getBalance(_token,_holderX); 
        uint256 _yBalance0 = getBalance(_token,_holderY);
        uint256 _lpToken = getBalance(_holderY,_holderX); //Remind 10**3 min liq burnt, adjust
        _lpToken += 10**3; //Todo Constant MIN_LIQ_BURNT on LP creation
        
        //uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 _totalLP = IERC20(_holderY).totalSupply();
        uint256 _y = _lpToken.mul(_yBalance0) / _totalLP;
        
        return (_x.add(_y),_x,_y,_lpToken.sub(10**3));
    }
    function getBalance(address _token, address _balOf) internal view returns(uint256){
        uint256 numOfTokens =IERC20(_token).balanceOf(_balOf);
        return numOfTokens;
    }
    
    function swapForFusii( uint256 _value, address _tokenBRoute) internal  returns(bool){
        //Dai 0xc7ad46e0b8a400bb3c915120d284aafba8fc4735
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Route2(AMM_ROUTEV2).WETH();
        path[1] = _tokenBRoute;
        //0xC50FFDFfab1A40A60c2532d8FEb9EE0CeD4AC29A repllace this?
        IUniswapV2Route2(AMM_ROUTEV2).swapExactETHForTokens{value:_value}
        (
            1,path, 0x0000000000000000000000000000000000000000, (block.timestamp+15 minutes));
    }
    function addUniswapLP(address _erc20Token,uint256 _amountTokenDesired,uint256 _value) internal returns(uint,uint,uint){
    //Create LP Address Constant UNIV2_ROUTE
       return IUniswapV2Route2(AMM_ROUTEV2).addLiquidityETH{value:_value}(
        _erc20Token,
        _amountTokenDesired,
        1,
        1,
        address(this),(block.timestamp+15 minutes)
    );
    }
    function removeUniswapLP(address token, uint liquidity) internal returns (uint amountToken, uint amountETH){
        address _pair = getPairAddress(token);
        IERC20(_pair).approve(AMM_ROUTEV2,IERC20(_pair).balanceOf(address(this)));
        return  IUniswapV2Route2(AMM_ROUTEV2).removeLiquidityETH(
         token,
        liquidity,
        1,
        1,
        address(this),(block.timestamp+15 minutes)
    );
    }
    /*Get Max ETH need to buy all the tokens*/
    
    /*Get Token from ETH via bancor*/
    function computeFTperETH(uint256 _tSupply, uint256 _pBal, uint32 _cRatio,uint256 _amnt) public view returns(uint256 ){
        return IBancorFormula(BF).calculatePurchaseReturn(_tSupply,_pBal,_cRatio,_amnt);
    }

    function computeFeePPM(uint256 amt, uint256 pct) public pure returns(uint ppm){
        require(amt.mul(pct)>=1000000);
        return amt.mul(pct)/1000000;
    }
    function getPairAddress(address _erc20Token) internal view returns(address pair){
    //Create Address Constant UNIV2_FACTORY, WETH 
        pair = IUniswapFactory(AMM_FACTORY).getPair(_erc20Token,0xc778417E063141139Fce010982780140Aa0cD5Ab);
        return pair;
    }
    //Compute Quote TODO determine which is TokenA and TokenB
    function computeQuote(uint256 amt,address _erc20Token,bool _isToken) public view returns(uint amountB){
        
        address pair = getPairAddress(_erc20Token);
        require(pair != address(0),"Pair doesn't exists");
        (uint256 reserveA,uint256 reserveB,) = IUniswapPair(pair).getReserves();
        require(amt > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        (_isToken)?amountB = (reserveA*1000000)/reserveB:amountB = (reserveB*1000000)/reserveA; //??
            
        amountB = amountB.mul(amt);
        return amountB.div(1000000);

    }

    function burnERC20Token(address _erc20Address,uint256 _tokenAmt) public returns(bool){
        burn(_tokenAmt);
        return true;
    }
    
    function unlockAndWithdrawNFT(bytes32 _receiptId, address _to) public returns(bool){
        receipts[_receiptId].seller = address(0);
        address nft = receipts[_receiptId].NFTContract;
        uint256 tknId = receipts[_receiptId].tokenId;
        nftIdtoRec[nft][tknId]= bytes32(0);
       // curveParameters[]
       //Tranfer NFT 
        IERC721(nft).safeTransferFrom(address(this),_to,tknId);
        return true;
    }
    
    
    function haveReceipt(bytes32 _receiptId)
        internal
        view
        returns (bool exists)
    {
        exists = (receipts[_receiptId].seller != address(0));
    }
    /*function receiptOwnerAddress(bytes32 _receiptId)
        internal
        view
        returns (address exists)
    {
        exists = receipts[_receiptId].seller;
    }
    function getReceiptId(address _nftAddr, uint _tknId)  public view returns (bytes32) {
         // You can get values from a nested mapping
         // even when it is not initialized
        return  nftIdtoRec[_nftAddr][_tknId];
    }*/
    function getReceiptData(bytes32 _receiptId) public
        
        view
        returns (
            address ,
            address ,
            uint256 ,
            address ,
            bool ,
            bool 

        )
        
    {
        if (haveReceipt(_receiptId) == false)
            return (address(0), address(0), 0,address(0), false, false);
        LockReceipt storage c = receipts[_receiptId];
        return (
            c.seller,
            c.NFTContract,
            c.tokenId,
            c.mintedERC20Addr,
            c.fusiiNFT,
            c.tradable
        );
    }
    function getCurve(address _erc20Address) public  
        view
        returns (
        uint256  poolBalanceReserve,
        uint32 rRatio,
        uint256 lastPrice,
        uint256 totalSupply,
        uint256 floorPrice,
        uint256 maxCap,
        bool rRatioType,
        uint256 dustBalance

        )
    {
       
        CurveRules storage c = curveParameters[_erc20Address];
        return (
            c.poolBalanceReserve,
            c.rRatio,
            c.lastPrice,
            c.totalSupply,
            c.floorPrice,
            c.maxCap,
            c.rRatioType,
            c.dustBalance
        );
    }
    
    receive() external payable {
        // custom function code
        require(msg.sender == address(AMM_ROUTEV2),"Not from AMM Route");
        //what to do with dust?
        emit Received(msg.value,msg.sender);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
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
library SafeMath {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

