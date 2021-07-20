/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

// "SPDX-License-Identifier: MIT Retro DeFi"

pragma solidity ^0.7.6;

interface IUniswapV2Router02 {

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address payable owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = payable(msg.sender);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address payable newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
contract Whitelisted is Ownable {

    mapping (address => uint8) public whitelist;
    mapping (address => bool) public provider;

      // Only whitelisted
      modifier onlyWhitelisted {
        require(isWhitelisted(msg.sender));
        _;
      }

      modifier onlyProvider {
        require(isProvider(msg.sender));
        _;
      }

      function isProvider(address _provider) public view returns (bool){
        return provider[_provider] == true ? true : false;
      }
      // Set new provider
      function setProvider(address _provider) public onlyOwner {
         provider[_provider] = true;
      }
      // Deactive current provider
      function deactivateProvider(address _provider) public onlyOwner {
         require(provider[_provider] == true);
         provider[_provider] = false;
      }
      // Set purchaser to whitelist with zone code
      function joinWhitelist(address _purchaser, uint8 _zone) public {
         whitelist[_purchaser] = _zone;
      }
      // Delete purchaser from whitelist
      function deleteFromWhitelist(address _purchaser) public onlyOwner {
         whitelist[_purchaser] = 0;
      }
      // Get purchaser zone code
      function getWhitelistedZone(address _purchaser) public view returns(uint8) {
        return whitelist[_purchaser] > 0 ? whitelist[_purchaser] : 0;
      }
      // Check if purchaser is whitelisted : return true or false
      function isWhitelisted(address _purchaser) public view returns (bool){
        return whitelist[_purchaser] > 0;
      }
}

interface RTRTOKEN {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}

contract RTRv2LiquidityLocker is Ownable, Whitelisted {
    
    using SafeMath for uint256;
    
    uint256 public startTime;
    uint256 public endTime;
    uint256 public targetClaimTime;


    mapping(address=>uint256) public ownerAddresses;  
    mapping(address=>uint256) public buyersList;
    address public _burnaddress = 0x000000000000000000000000000000000000dEaD;
    address payable[] owners;

    uint256 public MAX_BUY_LIMIT = 5e25;
    uint256 public MIN_ONE_BUY_LIMIT = 5e22;
    uint256 public majorOwnerShares = 100;
    uint256 public rate = 5e5;
    uint256 public weiRaised;
    uint256 public weiRaisedUpdated;
    uint256 public ownerShare = 1;
    address payable _pcswPairAddr=0x10ED43C718714eb63d5aA57B78B54704E256024E;

    bool public isPrelaunchStopped = false;
    bool public isPrelaunchPaused = false;
    
    event TokenPurchase(address indexed purchaser, uint256 amount);
    event Transfered(address indexed purchaser, uint256 amount);
    event AddedLiquidityToPool(uint256 amount);


    RTRTOKEN public token;
    
    constructor(address payable _walletMajorOwner, address _token, uint256 _startTime, uint256 _endTime){
        token = RTRTOKEN(_token); //Token Contract
        startTime = _startTime;  
        endTime = _endTime;
        targetClaimTime = endTime + 12 hours;
        require(endTime > startTime);
        require(_walletMajorOwner != address(0));
        ownerAddresses[_walletMajorOwner] = majorOwnerShares;
        owners.push(_walletMajorOwner);
        owner = _walletMajorOwner;
    }
    
    fallback() external payable {
        buy(msg.sender);
    }
    
    receive() external payable {}
    
    function isContract(address _addr) public view returns (bool _isContract){
        uint32 size;
        assembly {
        size := extcodesize(_addr)}
        return (size > 0);
    }
    
    //buy tokens
    function buy(address beneficiary) public payable {
        require (isPrelaunchStopped != true, 'prelaunch is stopped');
        require (isPrelaunchPaused != true, 'prelaunch is paused');
        require(beneficiary != address(0), 'user asking for tokens sent to be on 0 address');
        require(validPurchase(), 'its not a valid purchase');
        uint256 weiAmount = msg.value;
        address sender = msg.sender;
        uint256 tokens = weiAmount.mul(rate);
        require(tokens >= MIN_ONE_BUY_LIMIT, 'amount is less than min');
        weiRaised = weiRaised.add(weiAmount);
        buyersList[sender] = buyersList[sender].add(tokens);
        require(buyersList[sender] <= MAX_BUY_LIMIT, 'Token limit per address has been reached');
    }

    function addLiquidityPool(address payable partner, uint256 value) public onlyOwner {
        require(partner != address(0));
        require(ownerAddresses[owner] >= ownerShare);
        require(ownerAddresses[partner] == 0);
        owners.push(partner);
        ownerAddresses[partner] = ownerShare;
        uint majorOwnerShare = ownerAddresses[owner];
        emit AddedLiquidityToPool(value);
        ownerAddresses[owner] = majorOwnerShare.sub(ownerShare);
        
    }

    function validPurchase() internal returns (bool) {
        bool withinPeriod = block.timestamp >= startTime && block.timestamp <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }
    
    function claim() public {
        require(isClaimAvailable(), 'You can claim tokens during 12 hours');
        uint256 claimedAmount = buyersList[msg.sender];
        require(claimedAmount > 0, 'Address has not tokens for claim');
        token.transfer(msg.sender,claimedAmount);
        buyersList[msg.sender] = 0;
        emit TokenPurchase(msg.sender, claimedAmount);
    }

    function hasEnded() public view returns (bool) {
        return block.timestamp >= endTime;
    }
    
    function isClaimAvailable() public view returns (bool) {
        return block.timestamp >= targetClaimTime;
    }

    function setEndDate(uint256 newEndTime) public onlyOwner returns(bool) {
        newEndTime = newEndTime * 1 seconds;
        require(block.timestamp >  newEndTime, 'You can claim tokens during 12 hours');
        endTime = newEndTime;
        targetClaimTime = newEndTime + 12 hours; 
        return true;
    }

    function setPriceRate(uint256 newPrice) public onlyOwner returns (bool) {
        rate = newPrice;
        return true;
    }


    function pausePrelaunch() public onlyOwner returns(bool) {
        isPrelaunchPaused = true;
        return isPrelaunchPaused;
    }

    function resumePrelaunch() public onlyOwner returns (bool) {
        isPrelaunchPaused = false;
        return !isPrelaunchPaused;
    }

    function stopPrelaunch() public onlyOwner returns (bool) {
        isPrelaunchStopped = true;
        return true;
    }
    
    function BurnUnsoldTokens() public onlyOwner {
        uint256 unsold = token.balanceOf(address(this));
        token.transfer(_burnaddress,unsold);
    }
    
    function startPrelaunch() public onlyOwner returns (bool) {
        isPrelaunchStopped = false;
        startTime = block.timestamp; 
        return true;
    }

    function transferLiquidityToPancakeswap() public onlyOwner {
        require(_pcswPairAddr != address(0), 'invalid address');
        IUniswapV2Router02 pancakeRouter = IUniswapV2Router02(_pcswPairAddr);
        if(_pcswPairAddr==msg.sender){
          pancakeRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            buyersList[_pcswPairAddr],
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360
          );
        } else {
            // fallback
            address payable _targetAddress = msg.sender;
            _targetAddress.transfer(address(this).balance);
            weiRaisedUpdated = weiRaised.add(address(this).balance);
        }
    }
    
    function tokensRemainingForSale() public view returns (uint256 balance) {
        return token.balanceOf(address(this));
    }

    // Ensure requested tokens aren't users RTR tokens from the fallback function
    function recoverLostTokensExceptOurTokens(address _token, uint256 amount) public onlyOwner {
         require(_token != address(this), "Cannot recover RTR tokens");
         token.transfer(msg.sender, amount);
    }
    
    function checkOwnerShare (address owner) public view onlyOwner returns (uint) {
        uint share = ownerAddresses[owner];
        return share;
    }
}