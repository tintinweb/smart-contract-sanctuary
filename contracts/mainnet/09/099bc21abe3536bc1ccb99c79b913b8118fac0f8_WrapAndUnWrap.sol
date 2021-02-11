/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

/*
                                       `.-:+osyhhhhhhyso+:-.`
                                   .:+ydmNNNNNNNNNNNNNNNNNNmdy+:.
                                .+ymNNNNNNNNNNNNNNNNNNNNNNNNNNNNmy+.
                             `/hmNNNNNNNNmdys+//:::://+sydmNNNNNNNNmh/`
                           .odNNNNNNNdy+-.`              `.-+ydNNNNNNNdo.
                         `omNNNNNNdo-`                        `-odNNNNNNmo`
                        :dNNNNNNh/`                              `/hNNNNNNd:
                      `oNNNNNNh:                     /-/.           :hNNNNNNo`
                     `yNNNNNm+`                      mNNm-           `+mNNNNNy`
                    `hNNNNNd-                        hNNNm.            -dNNNNNh`
                    yNNNNNd.                         .ymNNh             .dNNNNNy
                   /NNNNNm.                            -mNNys+.          .mNNNNN/
                  `mNNNNN:                           `:hNNNNNNNs`         :NNNNNm`
                  /NNNNNh                          `+dNNNNNNNNNNd.         hNNNNN/
                  yNNNNN/               .:+syyhhhhhmNNNNNNNNNNNNNm`        /NNNNNy
                  dNNNNN.            `+dNNNNNNNNNNNNNNNNNNNNNNNmd+         .NNNNNd
                  mNNNNN`           -dNNNNNNNNNNNNNNNNNNNNNNm-             `NNNNNm
                  dNNNNN.          -NNNNNNNNNNNNNNNNNNNNNNNN+              .NNNNNd
                  yNNNNN/          dNNNNNNNNNNNNNNNNNNNNNNNN:              /NNNNNy
                  /NNNNNh         .NNNNNNNNNNNNNNNNNNNNNNNNd`              hNNNNN/
                  `mNNNNN:        -NNNNNNNNNNNNNNNNNNNNNNNh.              :NNNNNm`
                   /NNNNNm.       `NNNNNNNNNNNNNNNNNNNNNh:               .mNNNNN/
                    yNNNNNd.      .yNNNNNNNNNNNNNNNdmNNN/               .dNNNNNy
                    `hNNNNNd-    `dmNNNNNNNNNNNNdo-`.hNNh              -dNNNNNh`
                     `yNNNNNm+`   oNNmmNNNNNNNNNy.   `sNNdo.         `+mNNNNNy`
                      `oNNNNNNh:   ....++///+++++.     -+++.        :hNNNNNNo`
                        :dNNNNNNh/`                              `/hNNNNNNd:
                         `omNNNNNNdo-`                        `-odNNNNNNmo`
                           .odNNNNNNNdy+-.`              `.-+ydNNNNNNNdo.
                             `/hmNNNNNNNNmdys+//:::://+sydmNNNNNNNNmh/`
                                .+ymNNNNNNNNNNNNNNNNNNNNNNNNNNNNmy+.
                                   .:+ydmNNNNNNNNNNNNNNNNNNmdy+:.
                                       `.-:+yourewelcome+:-.`
 /$$$$$$$  /$$                                               /$$      /$$
| $$__  $$| $$                                              | $$$    /$$$
| $$  \ $$| $$  /$$$$$$  /$$   /$$ /$$   /$$  /$$$$$$$      | $$$$  /$$$$  /$$$$$$  /$$$$$$$   /$$$$$$  /$$   /$$
| $$$$$$$/| $$ /$$__  $$|  $$ /$$/| $$  | $$ /$$_____/      | $$ $$/$$ $$ /$$__  $$| $$__  $$ /$$__  $$| $$  | $$
| $$____/ | $$| $$$$$$$$ \  $$$$/ | $$  | $$|  $$$$$$       | $$  $$$| $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$  | $$
| $$      | $$| $$_____/  >$$  $$ | $$  | $$ \____  $$      | $$\  $ | $$| $$  | $$| $$  | $$| $$_____/| $$  | $$
| $$      | $$|  $$$$$$$ /$$/\  $$|  $$$$$$/ /$$$$$$$/      | $$ \/  | $$|  $$$$$$/| $$  | $$|  $$$$$$$|  $$$$$$$
|__/      |__/ \_______/|__/  \__/ \______/ |_______/       |__/     |__/ \______/ |__/  |__/ \_______/ \____  $$
                                                                                                        /$$  | $$
                                                                                                       |  $$$$$$/
                                                                                                       \______/
*/


// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.



pragma solidity 0.7.4;


interface ERC20 {
    function totalSupply() external view returns(uint supply);

    function balanceOf(address _owner) external view returns(uint balance);

    function transfer(address _to, uint _value) external returns(bool success);

    function transferFrom(address _from, address _to, uint _value) external returns(bool success);

    function approve(address _spender, uint _value) external returns(bool success);

    function allowance(address _owner, address _spender) external view returns(uint remaining);

    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface WrappedETH {
    function totalSupply() external view returns(uint supply);

    function balanceOf(address _owner) external view returns(uint balance);

    function transfer(address _to, uint _value) external returns(bool success);

    function transferFrom(address _from, address _to, uint _value) external returns(bool success);

    function approve(address _spender, uint _value) external returns(bool success);

    function allowance(address _owner, address _spender) external view returns(uint remaining);

    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function deposit() external payable;

    function withdraw(uint256 wad) external;

}

interface UniswapFactory{
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface LPERC20{

    function token0() external view returns(address);
    function token1() external view returns(address);
}



interface SushiV2{


   function addLiquidity ( address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline ) external returns ( uint256 amountA, uint256 amountB, uint256 liquidity );
   function addLiquidityETH ( address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline ) external returns ( uint256 amountToken, uint256 amountETH, uint256 liquidity );
   function removeLiquidityETH ( address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline ) external returns ( uint256 amountToken, uint256 amountETH );
   function removeLiquidity ( address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline ) external returns ( uint256 amountA, uint256 amountB );

   function swapExactTokensForTokens ( uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external returns ( uint256[] memory amounts );
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
   function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

}





library SafeMath {
  function mul(uint256 a, uint256 b) internal view returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal view returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }



  function sub(uint256 a, uint256 b) internal view returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal view returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}


contract WrapAndUnWrap{

  using SafeMath
    for uint256;

  address payable public owner;
  //placehodler token address for specifying eth tokens
  address public ETH_TOKEN_ADDRESS  = address(0x0);
  address public WETH_TOKEN_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  WrappedETH wethToken = WrappedETH(WETH_TOKEN_ADDRESS);
  uint256 approvalAmount = 1000000000000000000000000000000;
  uint256 longTimeFromNow = 1000000000000000000000000000;
  address sushiAddress = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
  address uniFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  SushiV2 sushiExchange = SushiV2(sushiAddress);
  UniswapFactory factory = UniswapFactory(uniFactoryAddress);
  mapping (address => address[]) public lpTokenAddressToPairs;
  mapping(string=>address) public stablecoins;
  mapping(address=>mapping(address=>address[])) public presetPaths;
  bool public changeRecpientIsOwner;
  uint256 public fee = 0;
  uint256 public maxfee = 0;


  modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
}

    fallback() external payable {
    }

  constructor() public payable {
         stablecoins["DAI"] = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
         stablecoins["USDT"] = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
         stablecoins["USDC"] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
         changeRecpientIsOwner = false;
        owner= msg.sender;

  }

  function wrap(address sourceToken, address[] memory destinationTokens, uint256 amount) public payable returns(address, uint256){


    ERC20 sToken = ERC20(sourceToken);
    ERC20 dToken = ERC20(destinationTokens[0]);

      if(destinationTokens.length==1){

        if(sourceToken != ETH_TOKEN_ADDRESS){
          require(sToken.transferFrom(msg.sender, address(this), amount), "You have not approved this contract or do not have enough token for this transfer 1");
          if(sToken.allowance(address(this), sushiAddress) < amount.mul(2)){
                  sToken.approve(sushiAddress, amount.mul(3));
            }
        }

        conductUniswap(sourceToken, destinationTokens[0], amount);
        uint256 thisBalance = dToken.balanceOf(address(this));
        dToken.transfer(msg.sender, thisBalance);
        return (destinationTokens[0], thisBalance);

      }

      else{

        bool updatedweth =false;
        if(sourceToken == ETH_TOKEN_ADDRESS){
          WrappedETH sToken1 = WrappedETH(WETH_TOKEN_ADDRESS);
          sToken1.deposit{value:msg.value}();
          sToken = ERC20(WETH_TOKEN_ADDRESS);
          amount = msg.value;
          sourceToken = WETH_TOKEN_ADDRESS;
          updatedweth =true;
        }


        if(sourceToken != ETH_TOKEN_ADDRESS && updatedweth==false){
          require(sToken.transferFrom(msg.sender, address(this), amount), "You have not approved this contract or do not have enough token for this transfer  2");
          if(sToken.allowance(address(this), sushiAddress) < amount.mul(2)){
                  sToken.approve(sushiAddress, amount.mul(3));
            }
        }

        if(destinationTokens[0] == ETH_TOKEN_ADDRESS){
              destinationTokens[0] = WETH_TOKEN_ADDRESS;
        }
        if(destinationTokens[1] == ETH_TOKEN_ADDRESS){
            destinationTokens[1] = WETH_TOKEN_ADDRESS;
        }



        if(sourceToken !=destinationTokens[0]){
            conductUniswap(sourceToken, destinationTokens[0], amount.div(2));
        }
        if(sourceToken !=destinationTokens[1]){

            conductUniswap(sourceToken, destinationTokens[1], amount.div(2));
        }

        ERC20 dToken2 = ERC20(destinationTokens[1]);
        uint256 dTokenBalance = dToken.balanceOf(address(this));
        uint256 dTokenBalance2 = dToken2.balanceOf(address(this));

        if(dToken.allowance(address(this), sushiAddress) < dTokenBalance.mul(2)){
             dToken.approve(sushiAddress, dTokenBalance.mul(3));
        }

        if(dToken2.allowance(address(this), sushiAddress) < dTokenBalance2.mul(2)){
            dToken2.approve(sushiAddress, dTokenBalance2.mul(3));
        }

        (,,uint liquidityCoins)  = sushiExchange.addLiquidity(destinationTokens[0],destinationTokens[1], dTokenBalance, dTokenBalance2, 1,1, address(this), longTimeFromNow);

        address thisPairAddress = factory.getPair(destinationTokens[0],destinationTokens[1]);
        ERC20 lpToken = ERC20(thisPairAddress);
        lpTokenAddressToPairs[thisPairAddress] =[destinationTokens[0], destinationTokens[1]];
        uint256 thisBalance =lpToken.balanceOf(address(this));

        if(fee>0){
            uint256 totalFee = (thisBalance.mul(fee)).div(10000);
            if(totalFee >0){
                lpToken.transfer(owner, totalFee);
            }
            thisBalance =lpToken.balanceOf(address(this));
            lpToken.transfer(msg.sender, thisBalance);

        }
        else{
            lpToken.transfer(msg.sender, thisBalance);
        }


        //transfer any change to changeRecipient (from a pair imbalance. Should never be more than a few basis points)
        address changeRecipient = msg.sender;
        if(changeRecpientIsOwner == true){
            changeRecipient = owner;
        }
        if(dToken.balanceOf(address(this)) >0){
            dToken.transfer(changeRecipient, dToken.balanceOf(address(this)));
        }
        if(dToken2.balanceOf(address(this)) >0){
            dToken2.transfer(changeRecipient, dToken2.balanceOf(address(this)));
        }

        return (thisPairAddress,thisBalance) ;
      }



    }

    function updateStableCoinAddress(string memory coinName, address newAddress) public onlyOwner returns(bool){
        stablecoins[coinName] = newAddress;
        return true;

    }

    function updatePresetPaths(address sellToken, address buyToken, address[] memory newPath ) public onlyOwner returns(bool){
        presetPaths[sellToken][buyToken] = newPath;
        return true;
    }

    //owner can turn on ability to collect a small fee from trade imbalances on LP conversions
    function updateChangeRecipientBool(bool changeRecpientIsOwnerBool ) public onlyOwner returns(bool){
        changeRecpientIsOwner = changeRecpientIsOwnerBool;
        return true;
    }



      function unwrap(address sourceToken, address destinationToken, uint256 amount) public payable returns( uint256){

        address originalDestinationToken = destinationToken;
        ERC20 sToken = ERC20(sourceToken);
        if(destinationToken == ETH_TOKEN_ADDRESS){
            destinationToken = WETH_TOKEN_ADDRESS;
        }
        ERC20 dToken = ERC20(destinationToken);

        if(sourceToken != ETH_TOKEN_ADDRESS){
          require(sToken.transferFrom(msg.sender, address(this), amount), "You have not approved this contract or do not have enough token for this transfer  3 unwrapping");
        }

        LPERC20 thisLpInfo = LPERC20(sourceToken);
        lpTokenAddressToPairs[sourceToken] = [thisLpInfo.token0(), thisLpInfo.token1()];

          if(lpTokenAddressToPairs[sourceToken].length !=0){
            if(sToken.allowance(address(this), sushiAddress) < amount.mul(2)){
                  sToken.approve(sushiAddress, amount.mul(3));
            }

          sushiExchange.removeLiquidity(lpTokenAddressToPairs[sourceToken][0], lpTokenAddressToPairs[sourceToken][1], amount, 0,0, address(this), longTimeFromNow);

          ERC20 pToken1 = ERC20(lpTokenAddressToPairs[sourceToken][0]);
          ERC20 pToken2 = ERC20(lpTokenAddressToPairs[sourceToken][1]);

          uint256 pTokenBalance = pToken1.balanceOf(address(this));
          uint256 pTokenBalance2 = pToken2.balanceOf(address(this));

           if(pToken1.allowance(address(this), sushiAddress) < pTokenBalance.mul(2)){
                  pToken1.approve(sushiAddress, pTokenBalance.mul(3));
            }

            if(pToken2.allowance(address(this), sushiAddress) < pTokenBalance2.mul(2)){
                  pToken2.approve(sushiAddress, pTokenBalance2.mul(3));
            }

          if(lpTokenAddressToPairs[sourceToken][0] != destinationToken){
              conductUniswap(lpTokenAddressToPairs[sourceToken][0], destinationToken, pTokenBalance);
          }
          if(lpTokenAddressToPairs[sourceToken][1] != destinationToken){
              conductUniswap(lpTokenAddressToPairs[sourceToken][1], destinationToken, pTokenBalance2);
          }


          uint256 destinationTokenBalance = dToken.balanceOf(address(this));

          if(originalDestinationToken == ETH_TOKEN_ADDRESS){
              wethToken.withdraw(destinationTokenBalance);
              if(fee >0){
                  uint256 totalFee = (address(this).balance.mul(fee)).div(10000);
                  if(totalFee >0){
                      owner.transfer(totalFee);
                  }
                  msg.sender.transfer(address(this).balance);
              }
              else{
                msg.sender.transfer(address(this).balance);
              }
          }
          else{
              if(fee >0){
                   uint256 totalFee = (destinationTokenBalance.mul(fee)).div(10000);
                   if(totalFee >0){
                       dToken.transfer(owner, totalFee);
                   }
                   destinationTokenBalance = dToken.balanceOf(address(this));
                   dToken.transfer(msg.sender, destinationTokenBalance);

              }
              else{
               dToken.transfer(msg.sender, destinationTokenBalance);
              }
          }


          return destinationTokenBalance;

        }

        else{

            if(sToken.allowance(address(this), sushiAddress) < amount.mul(2)){
                  sToken.approve(sushiAddress, amount.mul(3));
            }
            if(sourceToken != destinationToken){
                conductUniswap(sourceToken, destinationToken, amount);
            }
          uint256 destinationTokenBalance = dToken.balanceOf(address(this));
          dToken.transfer(msg.sender, destinationTokenBalance);
          return destinationTokenBalance;
        }

      }

  function updateOwnerAddress(address payable newOwner) onlyOwner public returns (bool){
     owner = newOwner;
     return true;
   }

   function updateSushiExchange(address newAddress ) public onlyOwner returns (bool){

    sushiExchange = SushiV2( newAddress);
    sushiAddress = newAddress;
    return true;

  }

  function updateUniswapFactory(address newAddress ) public onlyOwner returns (bool){

   factory = UniswapFactory( newAddress);
   uniFactoryAddress = newAddress;
   return true;

 }


  function conductUniswap(address sellToken, address buyToken, uint amount) internal returns (uint256 amounts1){

            if(sellToken ==ETH_TOKEN_ADDRESS && buyToken == WETH_TOKEN_ADDRESS){
                wethToken.deposit{value:msg.value}();
            }
            else if(sellToken == address(0x0)){

               // address [] memory addresses = new address[](2);
               address [] memory addresses = getBestPath(WETH_TOKEN_ADDRESS, buyToken, amount);
                //addresses[0] = WETH_TOKEN_ADDRESS;
                //addresses[1] = buyToken;
                sushiExchange.swapExactETHForTokens{value:msg.value}(0, addresses, address(this), 1000000000000000 );

            }

            else if(sellToken == WETH_TOKEN_ADDRESS){
                wethToken.withdraw(amount);

                //address [] memory addresses = new address[](2);
                address [] memory addresses = getBestPath(WETH_TOKEN_ADDRESS, buyToken, amount);
                //addresses[0] = WETH_TOKEN_ADDRESS;
                //addresses[1] = buyToken;
                sushiExchange.swapExactETHForTokens{value:amount}(0, addresses, address(this), 1000000000000000 );

            }



            else{

          address [] memory addresses = getBestPath(sellToken, buyToken, amount);
           uint256 [] memory amounts = conductUniswapT4T(addresses, amount );
           uint256 resultingTokens = amounts[amounts.length-1];
           return resultingTokens;
            }
    }


    //gets the best path to route the transaction on Uniswap
    function getBestPath(address sellToken, address buyToken, uint256 amount) public view returns (address[] memory){

        address [] memory defaultPath =new address[](2);
        defaultPath[0]=sellToken;
        defaultPath[1] = buyToken;


        if(presetPaths[sellToken][buyToken].length !=0){
            return presetPaths[sellToken][buyToken];
        }


        if(sellToken == stablecoins["DAI"] || sellToken == stablecoins["USDC"] || sellToken == stablecoins["USDT"]){
            return defaultPath;
        }
        if(buyToken == stablecoins["DAI"] || buyToken == stablecoins["USDC"] || buyToken == stablecoins["USDT"]){
            return defaultPath;
        }



        address[] memory daiPath = new address[](3);
        address[] memory usdcPath =new address[](3);
        address[] memory usdtPath =new address[](3);

        daiPath[0] = sellToken;
        daiPath[1] = stablecoins["DAI"];
        daiPath[2] = buyToken;

        usdcPath[0] = sellToken;
        usdcPath[1] = stablecoins["USDC"];
        usdcPath[2] = buyToken;

        usdtPath[0] = sellToken;
        usdtPath[1] = stablecoins["USDT"];
        usdtPath[2] = buyToken;


        uint256 directPathOutput =  getPriceFromUniswap(defaultPath, amount)[1];


        uint256[] memory daiPathOutputRaw = getPriceFromUniswap(daiPath, amount);
        uint256[]  memory usdtPathOutputRaw = getPriceFromUniswap(usdtPath, amount);
        uint256[]  memory usdcPathOutputRaw = getPriceFromUniswap(usdcPath, amount);

        //uint256 directPathOutput = directPathOutputRaw[directPathOutputRaw.length-1];
        uint256 daiPathOutput = daiPathOutputRaw[daiPathOutputRaw.length-1];
        uint256 usdtPathOutput = usdtPathOutputRaw[usdtPathOutputRaw.length-1];
        uint256 usdcPathOutput = usdcPathOutputRaw[usdcPathOutputRaw.length-1];

        uint256 bestPathOutput = directPathOutput;
        address[] memory bestPath = new address[](2);
        address[] memory bestPath3 = new address[](3);
        //return defaultPath;
        bestPath = defaultPath;

        bool isTwoPath = true;

        if(directPathOutput < daiPathOutput){
            isTwoPath=false;
            bestPathOutput = daiPathOutput;
            bestPath3 = daiPath;
        }
        if(bestPathOutput < usdcPathOutput){
            isTwoPath=false;
            bestPathOutput = usdcPathOutput;
            bestPath3 = usdcPath;
        }
         if(bestPathOutput < usdtPathOutput){
             isTwoPath=false;
            bestPathOutput = usdtPathOutput;
            bestPath3 = usdtPath;
        }

        require(bestPathOutput >0, "This trade will result in getting zero tokens back. Reverting");

        if(isTwoPath==true){
              return bestPath;
        }
        else{
            return bestPath3;
        }



    }

    function getPriceFromUniswap(address  [] memory theAddresses, uint amount) public view returns (uint256[] memory amounts1){


        try sushiExchange.getAmountsOut(amount,theAddresses ) returns (uint256[] memory amounts){
            return amounts;
        }
        catch  {
            uint256 [] memory amounts2= new uint256[](2);
            amounts2[0]=0;
            amounts2[1]=0;
            return amounts2;

        }

    }

    function conductUniswapT4T(address  [] memory theAddresses, uint amount) internal returns (uint256[] memory amounts1){

           uint256 deadline = 1000000000000000;
           uint256 [] memory amounts =  sushiExchange.swapExactTokensForTokens(amount, 0, theAddresses, address(this),deadline );
           return amounts;

    }

    function adminEmergencyWithdrawTokens(address token, uint amount, address payable destination) public onlyOwner returns(bool) {

      if (address(token) == ETH_TOKEN_ADDRESS) {
          destination.transfer(amount);
      }
      else {
          ERC20 tokenToken = ERC20(token);
          require(tokenToken.transfer(destination, amount));
      }
      return true;
  }


  function setFee(uint256 newFee) public onlyOwner returns (bool){
    require(newFee<=maxfee, "Admin cannot set the fee higher than the current maxfee");
    fee = newFee;
    return true;
  }


  function setMaxFee(uint256 newMax) public onlyOwner returns (bool){
    require(maxfee==0, "Admin can only set max fee once and it is perm");
    maxfee = newMax;
    return true;
  }

  function addLPPair(address lpAddress, address token1, address token2) onlyOwner public returns (bool){
      lpTokenAddressToPairs[lpAddress] = [token1, token2];
      return true;
  }

  function getLPTokenByPair(address token1, address token2) view public returns (address lpAddr){
      address thisPairAddress = factory.getPair(token1,token2);
      return thisPairAddress;
  }

   function getUserTokenBalance(address userAddress, address tokenAddress) public view returns (uint256){
    ERC20 token = ERC20(tokenAddress);
    return token.balanceOf(userAddress);

  }

}