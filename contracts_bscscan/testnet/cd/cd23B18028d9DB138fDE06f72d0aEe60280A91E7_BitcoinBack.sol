/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

interface IUniswapV2Router02{
    function WETH() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface ERC20{
   function balanceOf(address account) external view returns (uint256);
}

contract BitcoinBack{
  //0xcd23B18028d9DB138fDE06f72d0aEe60280A91E7
  string public constant _name = "BB";
  string public constant _symbol = "BB";
  uint8 public constant _decimals = 18;
  uint8 public constant _dividendTax = 10;
  uint8 public constant _marketingTax = 1;

  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
  event Transfer(address indexed from, address indexed to, uint tokens);

  mapping(address => uint256) _balances;
  mapping(address => mapping (address => uint256)) _allowances;
  uint256 public _totalSupply = 21000000 ether;

  address public pancakeRouter;
  address public bitcoin;
  address public marketingWallet;
  uint256 public totalDividends;//total dividends accumulated
  uint256 public minimumPayout = 420;
  address public WETH;
  mapping(address=>uint256) public lastClaim;//totalDividends lastClaim amount
  mapping(address=>bool) public excluded;//excluded from dividends
  mapping(uint160=>address) public earners;//list of dividend earners to be paid out
  uint160 public lastProcessedDividend;//index of last claim processed
  uint160 public totalEarners;
  bool public taxEnabled;
  uint256 public totalBitcoin;//total bitcoin paid out

  using SafeMath for uint256;
  //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 tesnet router https://pancake.kiemtienonline360.com
  //0x8301f2213c0eed49a7e28ae4c3e91722919b8b47 testnet busd
  constructor(address router,address btc) {
    marketingWallet=msg.sender;
    _balances[msg.sender] = _totalSupply;
    excluded[msg.sender]=true;
    excluded[pancakeRouter]=true;
    excluded[address(0)]=true;
    pancakeRouter=router;
    bitcoin=btc;
    _allowances[address(this)][pancakeRouter]=type(uint256).max;
    WETH=IUniswapV2Router02(pancakeRouter).WETH();
  }

  function totalSupply() public  view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address tokenOwner) public  view returns (uint256) {
    return _balances[tokenOwner];
  }

  function transfer(address receiver, uint256 numTokens) public  returns (bool) {
    require(numTokens <= _balances[msg.sender]);
    _transfer(msg.sender,receiver,numTokens);
    return true;
  }

  function approve(address delegate, uint256 numTokens) public  returns (bool) {
    _allowances[msg.sender][delegate] = numTokens;
    emit Approval(msg.sender, delegate, numTokens);
    return true;
  }

  function allowance(address owner, address delegate) public  view returns (uint) {
    return _allowances[owner][delegate];
  }

  function transferFrom(address owner, address receiver, uint256 numTokens) public  returns (bool) {
    require(numTokens <= _balances[owner]);
    require(numTokens <= _allowances[owner][msg.sender]);
    claim(msg.sender);
    if(owner!=address(this)){
      _allowances[owner][msg.sender] = _allowances[owner][msg.sender].sub(numTokens);
    }
    _transfer(owner,receiver,numTokens);
    return true;
  }
  function _transfer(address owner, address receiver,uint256 numTokens)internal{
    claim(msg.sender);
    claim(receiver);
    _balances[owner] = _balances[owner].sub(numTokens);
    if(taxEnabled==false){
        _balances[receiver] = _balances[receiver].add(numTokens);//remainign 89% post tax
    }
    else{
        uint256 remaining  = (numTokens*(uint256(100).sub(_marketingTax).sub(_dividendTax)))/100;
        _balances[receiver] = _balances[receiver].add(remaining);//remainign 89% post tax
        uint256 tax = (numTokens.sub(remaining));
        _balances[address(this)]=_balances[address(this)].add(tax);//total tax
        totalDividends.add(tax*10/11);
        address [] memory path=new address[](2);
        path[0]=address(this);
        path[1]=WETH;
        IUniswapV2Router02(pancakeRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        tax.sub(tax*10/11),
                        0,
                        path,
                        earners[lastProcessedDividend],
                        block.timestamp+300
                        );
        //_balances[marketingWallet]=_balances[marketingWallet].add(tax.sub(tax*10/11));//1% to marketingWallet
        if(lastClaim[receiver]==0&&excluded[receiver]==false){
            lastClaim[receiver]=totalDividends;
            totalEarners++;
            earners[totalEarners]=receiver;
        }
    }
    emit Transfer(owner, receiver, numTokens);
  }
  function enableTax()external{
      require(msg.sender==marketingWallet);
      taxEnabled=true;
  }
  function claim(address addy)public{
      //uint256 supply = _totalSupply - _balances[address(0)]- _balances[pancakeRouter];
      //uint256 payout = (totalDividends-lastClaim[msg.sender])*_balances[msg.sender]/supply;
      _claim(addy,
      (totalDividends-lastClaim[msg.sender])*_balances[msg.sender]/
        (_totalSupply - _balances[address(0)]- _balances[pancakeRouter]));
  }
  function _claim(address addy,uint256 payout)private{
      if(excluded[addy]!=true){
        // dividends portion * earner equity
        if(payout!=0){
            address [] memory path=new address[](2);
            path[0]=address(this);
            path[1]=WETH;
            path[2]=bitcoin;
            uint256 btc = ERC20(bitcoin).balanceOf(earners[lastProcessedDividend]);
            IUniswapV2Router02(pancakeRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                payout,
                0,
                path,
                addy,
                block.timestamp+300
                );
            totalBitcoin += ERC20(bitcoin).balanceOf(earners[lastProcessedDividend]) - btc;
        }
        lastClaim[addy]=totalDividends;
    }
  }
  function processDividends () public{
    if(taxEnabled==true){
        require(gasleft()>5000);
        uint256 supply = _totalSupply - _balances[address(0)]- _balances[pancakeRouter];
        address [] memory path=new address[](2);
        path[0]=address(this);
        path[1]=bitcoin;
        address start;
        while(gasleft()>50000){
            if(lastProcessedDividend==totalEarners){
                lastProcessedDividend=0;
            }
            else{
                lastProcessedDividend++;
            }
            if(excluded[earners[lastProcessedDividend]]!=true){
                // dividends portion * earner equity
                uint256 payout = (totalDividends-lastClaim[earners[lastProcessedDividend]])*
                _balances[earners[lastProcessedDividend]]/supply;
                if(payout>420){
                    _claim(earners[lastProcessedDividend],payout);
                }
            }
            if(start==address(0)){
                start=earners[lastProcessedDividend];
            }
            else if(start==earners[lastProcessedDividend]){
                break;
            }
        }
    }
  }
}

library SafeMath{
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