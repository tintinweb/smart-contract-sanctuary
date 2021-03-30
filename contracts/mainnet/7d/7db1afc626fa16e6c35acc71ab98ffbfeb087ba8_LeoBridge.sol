/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity ^0.8.2;
//SPDX-License-Identifier: MIT

/*
* LeoBridge: Swap ERC20 <--> BEP20
*
* @fbslo, 2021
*/

contract LeoBridge {
    address payable public owner;
    address public leo;
    string public hiveAccount;
    
    address public router; //UNSIWAP ROUTER
    IUniswapV2Router02 uniswapRouter;
    
    event Entry(address _inputToken, uint256 _inputAmount, uint256 _minAmountOut, uint256 outputAmount, address _recepient, address _outputToken);
    event Exit(address _exitToken, uint256 _inputAmount, uint256 _outputAmount, address recepient);
    
    modifier ownerOnly {
        require(msg.sender == owner, 'Restricted to owner');
        _;
    }

    constructor(address _router, address _leo, string memory _hiveAccount) {
        router = _router;
        owner = payable(msg.sender);
        leo = _leo;
        hiveAccount = _hiveAccount;
        uniswapRouter = IUniswapV2Router02(_router);
    }

    function entrance(address _inputToken, uint256 _inputAmount, uint256 _minAmountOut, address[] calldata _path, address _recepient, address _outputToken) public {
        require(_path[_path.length - 1] == leo, 'Trade must end with LEO');
        
        //You need to approve this contract to spend input tokens
        ERC20(_inputToken).transferFrom(msg.sender, address(this), _inputAmount);
        
        //Swap input token on uniswap for LEO
        ERC20(_inputToken).approve(address(router), _inputAmount);
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(_inputAmount, _minAmountOut, _path, address(this), block.timestamp + 15);
        
        //Unwrap LEO
        ERC20(leo).approve(address(leo), amounts[amounts.length - 1]);
        ERC20(leo).convertTokenWithTransfer(amounts[amounts.length - 1], hiveAccount); 
        
        emit Entry(_inputToken, _inputAmount, _minAmountOut, amounts[amounts.length - 1], _recepient, _outputToken);
    }

    function exit(address _exitToken, uint256 _inputAmount, uint256 _minAmountOut, address[] calldata _path, address _recepient) public {
        require(_path[0] == leo, 'Trade must start with LEO');
          
        //You need to approve this contract to spend LEO tokens
        ERC20(leo).transferFrom(msg.sender, address(this), _inputAmount);
        
        //Swap input token on uniswap for LEO
        ERC20(leo).approve(address(router), _inputAmount);
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(_inputAmount, _minAmountOut, _path, _recepient, block.timestamp + 15);
        
        emit Exit(_exitToken, _inputAmount, amounts[amounts.length - 1], _recepient);
    }
    
    //contract is stateless, so no tokens/ETH/BNB should ever be here.
    function rescue(address _token, uint256 _amount, bool _isETH) public ownerOnly {
        if (_isETH){
            owner.transfer(address(this).balance);
        } else {
            ERC20(_token).transfer(owner, _amount);
        }
    }
}

interface ERC20 {
    function balanceOf(address _owner) external returns (uint256);
    function transfer(address _to, uint _value) external;
    function transferFrom(address _from, address _to, uint _value) external;
    function approve(address _spender, uint _value) external;
    function convertTokenWithTransfer(uint256 amount, string memory username) external;
}

interface IUniswapV2Router02 {
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
}