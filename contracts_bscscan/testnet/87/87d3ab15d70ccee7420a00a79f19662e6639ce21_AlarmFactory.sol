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
    address private oracle = 0x19f7f3bF88CB208B0C422CC2b8E2bd23ee461DD1;
    bytes32 private jobId = "e7ef6994a42b4dc289b757a81cb5485f";
    uint256 public fee = 100000000000000000;
    
    struct userData {
        uint amountIn;
        address[] path;
        uint expectedTime;
        address to;
    }
    
    mapping(address => userData) public Data;
    mapping(uint => mapping(address => userData)) getUserData;
    event callUserDetails(address indexed user, uint256 amountToSwap, uint time, address alarm);
    
    constructor() public {
        setChainlinkToken(0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06);
    }
    
    receive() external payable {}
    
    modifier onlyOwner() {
        require(callee == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function setFee(uint256 newFee) public {
        fee = newFee;
    }
   
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
    
    function withdrawETH() public onlyOwner{
        require((address(this)).balance > 0, "cannot withdraw 0 balance");
        userData storage userCall = Data[callee];
        userCall.amountIn = (address(this)).balance ;
        payable(_msgSender()).transfer(address(this).balance);
    }
}

contract RigelAlarmClockTokens is ChainlinkClient, Context {
    IERC20 public swapToken;
    ISmartSwapRouter02 smartSwap = ISmartSwapRouter02(0x00749e00Af4359Df5e8C156aF6dfbDf30dD53F44);
    address public callee;
    address private oracle = 0x19f7f3bF88CB208B0C422CC2b8E2bd23ee461DD1;
    bytes32 private jobId = "e7ef6994a42b4dc289b757a81cb5485f";
    uint256 public fee = 100000000000000000;
    
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
       
        setChainlinkToken(0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06);
    }
    
    modifier onlyOwner() {
        require(callee == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function setFee(uint256 newFee) public {
        fee = newFee;
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
    
    function withdrawETH() public onlyOwner{
        require((address(this)).balance > 0, "cannot withdraw 0 balance");
        userData storage userCall = Data[callee];
        userCall.amountIn = (address(this)).balance ;
        payable(_msgSender()).transfer(address(this).balance);
    }
}

contract AlarmFactory is Context {
    RigelAlarmClock rac;
    RigelAlarmClockTokens rac2;
    address private owner;
    RigelAlarmClock[] public Alarm;
    RigelAlarmClockTokens[] public AlarmToken;
    IERC20 chainLink = IERC20(0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06);
    IERC20 RigelToken = IERC20(0x9f0227A21987c1fFab1785BA3eBa60578eC1501B);
    uint256 public oracleFee = 100000000000000000;
    
    event createAlarmForToken(address indexed sender, uint256 amountToSwap, uint time, address tokenAddress);
    
    constructor() public {
        owner = _msgSender();
    }
    
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function setOracleFee(uint256 Ofee) public onlyOwner {
        oracleFee = Ofee;
        rac.setFee(Ofee);
        rac2.setFee(Ofee);
    }

    function createAlarmToSwapETHforToken(IERC20 _swapToken, uint256 _amountIn,  uint _timeOf) public payable {
        RigelToken.transferFrom(_msgSender(), address(this), oracleFee);
        RigelAlarmClock alarm = (new RigelAlarmClock)();
        address(alarm).transfer(msg.value);
        chainLink.transfer( address(alarm), oracleFee);
        alarm.setPeriodToswapETHForTokens(_swapToken,_msgSender(), _amountIn, _timeOf);
        Alarm.push(alarm);
        emit createAlarmForToken(_msgSender(), _amountIn, _timeOf, address(alarm));
    }
    
    function createAlarmToSwapTokenForETH(IERC20 _swapToken, uint256 _amountIn,  uint _timeOf) public {
        RigelToken.transferFrom(_msgSender(), address(this), oracleFee);
        RigelAlarmClock alarm = new RigelAlarmClock();
        chainLink.transfer( address(alarm), oracleFee);
        alarm.setPeriodToswapTokensForETH(_swapToken,_msgSender(), _amountIn, _timeOf);
        Alarm.push(alarm);
        emit createAlarmForToken(_msgSender(), _amountIn, _timeOf, address(alarm));
    }
    
    function swapExactTokens(IERC20 inputToken, IERC20 outputToken, uint256 _amountIn, uint _timeOf) public {
        RigelToken.transferFrom(_msgSender(), address(this), oracleFee);
        RigelAlarmClockTokens alarm = new RigelAlarmClockTokens();
        chainLink.transfer( address(alarm), oracleFee);
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