//SPDX-License-Identifier: unlicensed

pragma solidity 0.7.1;

import "./IUniswapV2Router02.sol";

contract UniswapExample {
  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;
  address public _owner;

  IUniswapV2Router02 public uniswapRouter;
  address private multiDaiKovan = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
  
  modifier onlyOwner() {
        require(msg.sender == _owner, "You're not the owner of the contract");
        _;
    }

  constructor() payable {
    uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    _owner = msg.sender;
  }
  
  

  function convertEthToDai(uint daiAmount) public payable {
    uint deadline = block.timestamp + 120; // using 'now' for convenience, for mainnet pass deadline from frontend!
    uniswapRouter.swapETHForExactTokens{ value: msg.value }(daiAmount, getPathForETHtoDAI(), address(this), deadline);
    
    // refund leftover ETH to user
    //(bool success,) = msg.sender.call{ value: address(this).balance }("");
    //require(success, "refund failed");
  }
  
  function getEstimatedETHforDAI(uint daiAmount) public view returns (uint[] memory) {
    return uniswapRouter.getAmountsIn(daiAmount, getPathForETHtoDAI());
  }

  function getPathForETHtoDAI() private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = multiDaiKovan;
    
    return path;
  }
  
  // important to receive ETH
  receive() payable external {}

    function getBalanceContract() public view returns(uint){
        return address(this).balance;
    }
  
  function withdraw(uint amount) public onlyOwner returns(bool) {
        require(amount <= address(this).balance);
        payable(_owner).transfer(amount);
        return true;

    }
}