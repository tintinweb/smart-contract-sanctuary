/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.8.0;


interface ERC20Interface {
    function decimals() external view returns (uint8);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

interface UniswapInterface {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

contract Uniswap {
    
    UniswapInterface public constant uniswapRouter = UniswapInterface(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    // function transferFrom(address _token, uint _amt) internal {
    //   ERC20Interface _tokenContract = ERC20Interface(_token);
    //   require(_tokenContract.transferFrom(msg.sender, address(this), _amt), 'transferFrom-failed.');
    // }
    // function approve(address _token, uint _amt) internal returns(bool success) {
    //     ERC20Interface _tokenContract = ERC20Interface(_token);
    //     require(_tokenContract.approve(address(uniswapRouter), _amt), 'approve failed.');
    // }
    //function swapETHForERC20(address _token) public payable {
       // address[] memory _path = new address[](2);
        //_path[0] = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
        //_path[1] = _token;
        //uniswapRouter.swapExactETHForTokens{value: msg.value}(0, _path, msg.sender, block.timestamp);
    //}
    function swapExactTokensForETH(uint _amt, address _token) public payable {
        ERC20Interface _tokenContract = ERC20Interface(_token);
        require(_tokenContract.approve(_token, _amt), 'approve failed.');
        require(_tokenContract.transferFrom(msg.sender, address(this), _amt), 'transferFrom-failed.');
        address[] memory _path = new address[](2);
        _path[0] = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
        _path[1] = uniswapRouter.WETH();
        uniswapRouter.swapExactTokensForETH(_amt, 0, _path, msg.sender, block.timestamp);
    }
    
    
}