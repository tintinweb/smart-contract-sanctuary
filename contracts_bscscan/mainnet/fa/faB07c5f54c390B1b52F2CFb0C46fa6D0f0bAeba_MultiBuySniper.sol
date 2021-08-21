/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

pragma solidity ^0.5.17;

contract UniswapV2Router02 {

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline) 
    external payable returns (uint[] memory amounts);

    address public WETH;
}

contract UniswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract ERC20 {
    function balanceOf (address account) external view returns (uint256);
}

contract MultiBuySniper { 

    UniswapV2Router02 public router = UniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    UniswapFactory public factory = UniswapFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    ERC20 public weth = ERC20(router.WETH());

    address payable public owner;
    uint public n = 20;
    uint public amt = 1000000000000000000;
    uint lowThresh = 100 ether;
    uint highThresh = 50000 ether;
    address public tokenAddr = 0xe5D46cC0Fd592804B36F9dc6D2ed7D4D149EBd6F;

    address[] public path = [router.WETH(), tokenAddr];

    constructor() public payable {
        owner = msg.sender;
    }

    function() external payable {
    }

    function withdraw() external {
        require(msg.sender==owner);
        owner.transfer(address(this).balance);
    }

    function swapit() external {
        require(address(this).balance > 0, "no balance");
        address _poolAddr = factory.getPair(address(path[1]), address(weth));
        uint _poolBal = weth.balanceOf(_poolAddr);
        require(_poolBal > lowThresh, "no liq");
        require(_poolBal < highThresh, "bad price");

        for (uint i=0; i<n; i++) {
            if (address(this).balance == 0) {
                return;
            }
            router.swapExactETHForTokens.value(amt)(1, path, owner, now);
        }

    }

    function changeParams(address _token, uint _amt, uint _low, uint _high, uint _n) external {
        require(msg.sender==owner);
        path[1] = _token;
        tokenAddr = _token;
        amt = _amt;
        lowThresh = _low;
        highThresh = _high;
        n = _n;
    }


    function viewStatus() public view returns(address _token, 
                                              uint _lowThresh, 
                                              uint _highThresh, 
                                              uint _amt,
                                              uint _n) {
        return (path[1], lowThresh, highThresh, amt, n);
    }


}