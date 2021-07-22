/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function depositBalance(address from, address to, uint value) external returns (bool);
}


interface IPancakeRouter {
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);  
  function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
}

interface IWBNB {
    function withdraw(uint) external;
    function deposit() external payable;
}



contract TestSwap{
    
    address private constant PANCAKE_V2_ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address private _owner;
    
    
    constructor() {

        _owner = msg.sender;
    }
    
    
    
     modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to) external onlyOwner returns(bool success) {
           
            require(IERC20(WBNB).balanceOf(address(this)) >= _amountIn, "Not enough WBNB in the contract");
            address[] memory path;
        if (_tokenIn != WBNB){
            path = new address[](3);
            path[0] = WBNB;
            path[1] = _tokenIn;
            path[2] = _tokenOut;
        } else {
            path = new address[](2);
            path[0] = WBNB;
            path[1] = _tokenOut;
        }
            
            IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, address(this), block.timestamp + 30);
            
        }
        
        
        function sell(address _token, uint amountSell, uint amountOutMin) external onlyOwner returns(bool success) {   
        require(IERC20(_token).balanceOf(address(this)) >= amountSell, "Not enough TOKEN in the contract");
        IERC20(_token).approve(PANCAKE_V2_ROUTER, amountSell);
        address[] memory path;
        path = new address[](2);
        path[0] = _token;
        path[1] = WBNB;
        IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(
              amountSell,
              amountOutMin,
              path, 
              address(this),
              block.timestamp + 30
        );
        return true;
        }
        
        function deposit() external payable {
        IWBNB(WBNB).deposit{value: msg.value}();
        IERC20(WBNB).approve(PANCAKE_V2_ROUTER, msg.value);
        }
        
        function withdrawToken(address _tokenAddress) public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        address to = _owner;
        IERC20(_tokenAddress).transfer(to, balance);
        }
        
        function approve(address _tokenIn,uint amount) public {
          // Calling this function first from remix
          IERC20(_tokenIn).approve(address(PANCAKE_V2_ROUTER), amount);
        }
        
        function transferFrom(address _tokenIn,uint amount) public {
          // Then calling this function from remix
          
          IERC20(_tokenIn).transferFrom(msg.sender, address(this), amount);
        }
        
        function checkBal(address token) public view returns(uint) {
            IERC20 token = IERC20(token);
            return token.balanceOf(address(this));
        }
        
        function getOwner() external view returns (address) {
        return _owner;
        }
        
        function getBalance() public view returns (uint) {
        return address(this).balance;
        }
}