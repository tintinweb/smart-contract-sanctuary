/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

pragma solidity 0.8.0;



interface IPancakeRouter {

  //modifier ensure(uint deadline) {
  //    require(deadline >= block.timestamp, 'PancakeRouter: EXPIRED');
  //    _;
  //}

  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      //ensure(deadline)
      returns (uint[] memory amounts);
}

contract Dimas {

  address constant BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
  address constant PancakeRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
  address constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;


  function buySomeTokens() external payable returns(bool){
    require((msg.value/100)*100 == msg.value, 'Too small');
    uint256 bnbToSend = (msg.value*90)/100;
    address[] memory path = new address[](2);
    path[0] = WBNB;
    path[1] = BUSD;
    IPancakeRouter(PancakeRouter).swapExactETHForTokens{value: bnbToSend}(1e18, path, msg.sender, block.timestamp);
    return true;

  }

}