// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ChainlinkClient.sol";

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface ISmartSwapRouter02 {
    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract RigelAlarmClock is ChainlinkClient, Context {
    IERC20 public swapToken;
    ISmartSwapRouter02 smartSwap = ISmartSwapRouter02(0x00749e00Af4359Df5e8C156aF6dfbDf30dD53F44);
    address public contractAddress = address(this);
    address public callee;
    address private oracle = 0x46cC5EbBe7DA04b45C0e40c061eD2beD20ca7755;
    bytes32 private jobId = "842e5f3cbcd34f76bf416d92b47ed416";
    uint256 private fee = 0.1 * 10 ** 18; // 0.1 LINK
    
    struct userData {
        uint amountIn;
        uint amountOutMin;
        address[] path;
        uint expectedTime;
        address to;
    }
    
    mapping(address => userData) public Data;
    mapping(uint => mapping(address => userData)) getUserData;
    event callUserDetails(address indexed user, uint256 amountToSwap, uint time, address alarm);
    
    constructor() public {
    //     smartSwap = ISmartSwapRouter02(0x00749e00Af4359Df5e8C156aF6dfbDf30dD53F44);
        
    //     contractAddress = address(this);
        setChainlinkToken(0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06);
        // oracle = 0x46cC5EbBe7DA04b45C0e40c061eD2beD20ca7755;
        // jobId = "842e5f3cbcd34f76bf416d92b47ed416";
        // fee = 0.1 * 10 ** 18; // 0.1 LINK
    }
    
   receive() external payable {}
   
    function setPeriodToswapETHForTokens(IERC20 _swapToken, address caller, uint256 _amountIn,  uint _timeOf) external payable returns (bytes32 requestId){
        callee = caller;
        userData storage _userData = Data[caller];
        swapToken = _swapToken;
        
        address[] memory path = new address[](2);
        path[0] = smartSwap.WETH();
        path[1] = address(_swapToken);
        
        _userData.path = [path[0], path[1]];
        _userData.amountIn = _amountIn;
        _userData.expectedTime = block.timestamp + (_timeOf);
        _userData.to = address(callee);
        
        
         Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfillAlarm.selector);
        // This will return in 90 seconds
        
        request.addUint("until", block.timestamp + _timeOf);
        return sendChainlinkRequestTo(oracle, request, fee);
        
    }
    
    function setPeriodToswapTokensForETH(IERC20 _swapToken, address caller, uint256 _amountIn,  uint _timeOf) external returns (bytes32 requestId){
        callee = caller;
        userData storage _userData = Data[caller];
        swapToken = _swapToken;
        address[] memory path = new address[](2);
           
        path[0] = address(_swapToken);
        path[1] = smartSwap.WETH();
        _userData.path = [path[0], path[1]];
        
        _userData.amountIn = _amountIn;
        _userData.expectedTime = block.timestamp + (_timeOf);
        _userData.to = address(callee);
        
        
         Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfillAlarm.selector);
        // This will return in 90 seconds
        
        request.addUint("until", block.timestamp + _timeOf);
        return sendChainlinkRequestTo(oracle, request, fee);
        
    }
    
    function fulfillAlarm(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId) {
     
        userData storage userCall = Data[callee];
        
        if(userCall.path[1] == smartSwap.WETH()) {
            swapToken.transferFrom(callee, address(this), userCall.amountIn);
            swapToken.approve(address(smartSwap), userCall.amountIn);
            
            uint256[] memory getcurrentPrice = smartSwap.getAmountsOut(
                userCall.amountIn,
                userCall.path
            );
        
            smartSwap.swapTokensForExactETH(
                getcurrentPrice[1],
                userCall.amountIn,
                userCall.path,
                address(callee),
                block.timestamp + 300
            );
            emit callUserDetails(callee, userCall.amountIn, block.timestamp, address(this));
        }else {
            smartSwap.swapExactETHForTokens{value: userCall.amountIn}(
                1,
                userCall.path,
                address(callee),
                block.timestamp + 120
            );
            emit callUserDetails(callee, userCall.amountIn, block.timestamp, address(this));
        }
    }
    
    function withdrawETH() public {
        payable(_msgSender()).transfer(address(this).balance);
    }
    
    function withdrawLink() external {
        LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
        require(linkToken.transfer(msg.sender, linkToken.balanceOf(address(this))), "Unable to transfer");
    }
}

contract RigelAlarmClockTokens is ChainlinkClient, Context {
    IERC20 public swapToken;
    ISmartSwapRouter02 smartSwap = ISmartSwapRouter02(0x00749e00Af4359Df5e8C156aF6dfbDf30dD53F44);
    address public callee;
    address private oracle = 0x46cC5EbBe7DA04b45C0e40c061eD2beD20ca7755;
    bytes32 private jobId = "842e5f3cbcd34f76bf416d92b47ed416";
    uint256 private fee = 0.1 * 10 ** 18;
    
    struct userData {
        uint amountIn;
        uint amountOutMin;
        address[] path;
        uint expectedTime;
        address to;
    }
    
    mapping(address => userData) public Data;
    mapping(uint => mapping(address => userData)) getUserData;
    event callUserDetails(address indexed user, uint256 amountToSwap, uint time, address alarm);
    
    constructor() public {
        /*
        smartSwap = ISmartSwapRouter02(0x00749e00Af4359Df5e8C156aF6dfbDf30dD53F44);
        
        oracle = 0x46cC5EbBe7DA04b45C0e40c061eD2beD20ca7755;
        jobId = "842e5f3cbcd34f76bf416d92b47ed416";
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        contractAddress = address(this);
        */
        setChainlinkToken(0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06);
    }
    
    function callToSwapExactTokens(IERC20 inputToken, IERC20 outputToken, address caller, uint256 _amountIn, uint _timeOf) public returns (bytes32 requestId) {
        callee = caller;
        userData storage _userData = Data[caller];
        swapToken = inputToken;
        address[] memory path = new address[](2);
        
        path[0] = address(inputToken);
        path[1] = address(outputToken);
        _userData.path = [path[0], path[1]];
        
        _userData.amountIn = _amountIn;
        _userData.expectedTime = block.timestamp + (_timeOf);
        _userData.to = address(callee);
        
        
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfillAlarm.selector);
        // This will return in 90 seconds
        
        request.addUint("until", block.timestamp + _timeOf);
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    
    function fulfillAlarm(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId) {
     
        userData storage userCall = Data[callee];
        
        swapToken.transferFrom(callee, address(this), userCall.amountIn);
        
        swapToken.approve(address(smartSwap), userCall.amountIn);
        
        uint256[] memory getcurrentPrice = smartSwap.getAmountsOut(
            userCall.amountIn,
            userCall.path
        );
    
        smartSwap.swapExactTokensForTokens(
            userCall.amountIn,
            getcurrentPrice[1],
            userCall.path,
            address(callee),
            block.timestamp + 300
        );
        emit callUserDetails(callee, userCall.amountIn, block.timestamp, address(this));
    }
    
    function withdrawETH() public {
        payable(_msgSender()).transfer(address(this).balance);
    }
    
    function withdrawLink() external {
        LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
        require(linkToken.transfer(msg.sender, linkToken.balanceOf(address(this))), "Unable to transfer");
    }
}

contract AlarmFactory is Context {
    address private owner;
    RigelAlarmClock[] public Alarm;
    RigelAlarmClockTokens[] public AlarmToken;
    IERC20 chainLink = IERC20(0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06);
    IERC20 RigelToken = IERC20(0x9f0227A21987c1fFab1785BA3eBa60578eC1501B);
    uint256 public oracleFee = 0.01E18;
    
    event createAlarmForToken(address indexed sender, uint256 amountToSwap, uint time, address tokenAddress);
    constructor() public {
        owner = _msgSender();
    }
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function setOracleFee(uint256 fee) public onlyOwner {
        oracleFee = fee;
    }
    function createAlarmToSwapETHforToken(IERC20 _swapToken, uint256 _amountIn,  uint _timeOf) public payable {
        RigelToken.transferFrom(_msgSender(), address(this), oracleFee);
        RigelAlarmClock alarm = (new RigelAlarmClock)();
        address(alarm).transfer(msg.value);
        chainLink.transfer( address(alarm), 0.1e18);
        alarm.setPeriodToswapETHForTokens(_swapToken,_msgSender(), _amountIn, _timeOf);
        Alarm.push(alarm);
        emit createAlarmForToken(_msgSender(), _amountIn, _timeOf, address(alarm));
    }
    
    function createAlarmToSwapTokenForETH(IERC20 _swapToken, uint256 _amountIn,  uint _timeOf) public {
        RigelToken.transferFrom(_msgSender(), address(this), oracleFee);
        RigelAlarmClock alarm = new RigelAlarmClock();
        chainLink.transfer( address(alarm), 0.1e18);
        alarm.setPeriodToswapTokensForETH(_swapToken,_msgSender(), _amountIn, _timeOf);
        Alarm.push(alarm);
        emit createAlarmForToken(_msgSender(), _amountIn, _timeOf, address(alarm));
    }
    
    function swapExactTokens(IERC20 inputToken, IERC20 outputToken, uint256 _amountIn, uint _timeOf) public {
        RigelToken.transferFrom(_msgSender(), address(this), oracleFee);
        RigelAlarmClockTokens alarm = new RigelAlarmClockTokens();
        chainLink.transfer( address(alarm), 0.1e18);
        alarm.callToSwapExactTokens(inputToken, outputToken, _msgSender(), _amountIn, _timeOf);
        AlarmToken.push(alarm);
        emit createAlarmForToken(_msgSender(), _amountIn, _timeOf, address(alarm));
    }
    
    function withdrawETH() public onlyOwner{
        payable(_msgSender()).transfer(address(this).balance);
    }
    
    function withdrawLink() external onlyOwner{
        // LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
        require(chainLink.transfer(_msgSender(), chainLink.balanceOf(address(this))), "Unable to transfer");
    }
    
    function withdrawToken(address tokAddress) public onlyOwner {
        IERC20(tokAddress).transfer(_msgSender(), IERC20(tokAddress).balanceOf(address(this)));
    }
    
    function getAlarmInfo(uint _index)
        public
        view
        returns (
            address _owner,
            uint balance
        )
    {
        RigelAlarmClock alarm = Alarm[_index];

        return (alarm.callee(), address(alarm).balance);
    }
}