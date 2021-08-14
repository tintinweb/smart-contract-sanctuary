/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-28
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
    function withdraw(uint amount) external;
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
}



contract BotContract{
    
    address private constant PANCAKE_V2_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address private _owner;
    enum botState {startSnipe,notStarted,voteLocked,Reset}
    
    botState public sniperState;
    
    mapping(address => uint) public players;
    
    address[] currentPlayers;
   
    constructor() {
        _owner = msg.sender;
        sniperState = botState.notStarted;
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
        address _to) external  returns(bool success) {
           
            require(IERC20(WBNB).balanceOf(address(this)) >= _amountIn, "Not enough WBNB in the contract");
            require(sniperState == botState.startSnipe);
            
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
        
            
            IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp + 30);
           
            
        }
        
        
        function swapMulti(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOutMin,
        address _to) external  returns(bool success) {
           
            require(sniperState == botState.startSnipe);
        
            for(uint i = 0; i < currentPlayers.length; i ++) {
            this.approve(_tokenIn, players[currentPlayers[i]]);
            this.swap(_tokenIn , _tokenOut, players[currentPlayers[i]], _amountOutMin, currentPlayers[i]);
            delete players[currentPlayers[i]];
            }
            
            
            
            
        }
        
        
        
        function deposit() external payable {
        IWBNB(WBNB).deposit{value: msg.value}();
        IERC20(WBNB).approve(PANCAKE_V2_ROUTER, msg.value);
        players[msg.sender] += msg.value;
        currentPlayers.push(msg.sender);
        
        }
        
        function withdrawToken(address _tokenAddress) public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(msg.sender);
        IERC20(_tokenAddress).transfer(msg.sender, balance);
        }
        
        function withdrawBNB(address payable _addr) public {
            IWBNB(WBNB).withdraw(players[msg.sender]);
            _addr.transfer(players[msg.sender]);
            delete players[msg.sender];
        }
        
        
        fallback() external payable {}

        
        
        function transferFrom(address _tokenIn,uint amount) public onlyOwner {
          // Then calling this function from remix
          
          IERC20(_tokenIn).transferFrom(msg.sender, address(this), amount);
        }

        
        function resetSnipe(address payable _addr) external {
            require(sniperState == botState.startSnipe);
            delete currentPlayers;
            sniperState = botState.notStarted;
        }
        
        function approve(address _tokenIn,uint amount) public {
          // Calling this function first from remix
          IERC20(_tokenIn).approve(address(PANCAKE_V2_ROUTER), amount);
        }
        
        function checkBal(address token) public view returns(uint) {
            IERC20 token = IERC20(token);
            return token.balanceOf(address(this));
        }
        
        function getContribution(address _addr) public view returns (uint)  {
        return players[_addr];
        }
        
        function getOwner() external view returns (address) {
        return _owner;
        }
        
        function getBalance() public view returns (uint) {
        return address(this).balance;
        }
        
        function getBlockNumber() public view returns (uint) {
            return block.number;
        }
        
        
        function startSnipe() public onlyOwner {
            sniperState = botState.startSnipe;
        }
    
        function notStarted() public onlyOwner {
            sniperState = botState.notStarted;
        }
        
        function voteLocked() public onlyOwner {
            sniperState = botState.voteLocked;
        }
    
        function resetBot() public onlyOwner {
            sniperState = botState.Reset;
        }
}