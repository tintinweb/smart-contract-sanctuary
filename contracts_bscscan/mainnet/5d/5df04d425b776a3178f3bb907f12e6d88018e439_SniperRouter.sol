/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

pragma solidity 0.8.6;

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPair {
    function getReserves() external returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface ISwap {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

interface IERC20 {
    function balanceOf(address user) external returns (uint256);
    function transfer(address user, uint256 amount) external;
    function approve(address user, uint256 amount) external;
}

contract SniperRouter {
    address payable public owner;
    IFactory public factory;
    ISwap public swap;

    address public token0;
    address public token1;
    address[] public path;
    uint public amountIn;
    uint public minOut;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    modifier onlyOwner(){
        require(msg.sender == owner, 'Sniper: only owner');
        _;
    }

    constructor(){
        factory = IFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
        swap = ISwap(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        owner = payable(tx.origin);
    }

    

    function verifyPathExistence() public view {
        for (uint256 i = 0; i < path.length - 1; i++){
          require(factory.getPair(path[i], path[i+1]) != address(0), "Path does not exist");
        }
    }

    function safebuy(address token, uint256 _amountIn) external {
        address[] memory _path = new address[](2);
        _path[0] = WBNB;
        _path[1] = token;
        path = _path;
        amountIn = _amountIn;
        minOut = 0;
        
        verifyPathExistence();

        IERC20(path[0]).approve(address(swap), amountIn);
        swap.swapExactTokensForTokens(amountIn, minOut, path, address(this), block.timestamp + 1);
        
        
        
      uint256 _amountIn = 1;
      _path[0] = token;
      _path[1] = WBNB;

      IERC20(token).approve(address(swap), amountIn);
      swap.swapExactTokensForTokens(_amountIn, minOut, _path, owner, block.timestamp + 1);
      
      
    }

    function sell(address token, uint256 _minOut) external {
      
      uint256 _amountIn = IERC20(token).balanceOf(address(this));
      address[] memory _path = new address[](2);
      _path[0] = token;
      _path[1] = WBNB;

      IERC20(token).approve(address(swap), amountIn);
      swap.swapExactTokensForTokens(_amountIn, _minOut, _path, owner, block.timestamp + 1);
    }

    function transfer() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function transferToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner, amount);
    }

    function call(address target, uint value, string memory signature, bytes memory data) external onlyOwner {
        bytes memory callData;

        if (bytes(signature).length == 0) callData = data;
        else callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);

        (bool success, ) = target.call{value:value}(callData);
        require(success, "execution reverted.");
    }

    fallback() external payable {}
    receive() external payable {}

    function sendToMultiple(address[] calldata _users, uint256 _amount, address _token) external payable onlyOwner {
        require(msg.value > _users.length * _amount, 'Sniper: value < length * amount');
        if (_token == address(0)){
            for (uint256 i = 0; i < _users.length; i++){
                payable(_users[i]).transfer(_amount);
            }
        } else {
            for (uint256 i = 0; i < _users.length; i++){
                IERC20(_token).transfer(_users[i], _amount);
            }
        }
    }

    function settings(address _owner, address _factory, address _swap) external onlyOwner {
        factory = IFactory(_factory);
        swap = ISwap(_swap);
        owner = payable(_owner);
    }
}