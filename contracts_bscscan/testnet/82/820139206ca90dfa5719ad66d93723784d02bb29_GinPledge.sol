pragma solidity 0.5.8;
 
import "./SafeMath.sol";
import "./SafeERC20.sol";
 
contract GinPledge {
    using SafeMath for uint256;
    using SafeERC20 for address;
 
    address private owner;
    address private profitor;
    bool _isDIS = true;
 
    mapping(address => PledgeOrder) _orders;
    mapping(address => uint256) _takeProfitTime;
 
    address _TokenFil;
    address _TokenFisc;
    KeyFlag[] keys;
 
    uint256 size;
    uint256 _maxPledgeAmount; 
    uint256 _maxMiningAmount;
    uint256 _leftMiningAmount;
    uint256 _minAmount;
    uint256 _totalPledegAmount;
    uint256 _maxPreMiningAmount;
    uint256 _startTime;
    uint256 _endTime;
    uint256 _precentUp=100;
    uint256 _precentDown=100;
 
    struct PledgeOrder {
        bool isExist;
        uint256 fiscToken;
        uint256 filToken;
        uint256 time;
        uint256 index;
    }
 
    struct KeyFlag {
        address key;
        bool isExist;
    }
 
    constructor (
        address FilTokenAddress,
        address FiscTokenAddress,
        address paramProfitor,
        uint256 maxPledgeAmount,
        uint256 minAmount,
        uint256 maxMiningAmount,
        uint256 maxPreMiningAmount,
        uint256 startTime,
        uint256 endTime
    ) 
        public 
    {
        _TokenFil  = address(FilTokenAddress);
        _TokenFisc = address(FiscTokenAddress);
        owner = msg.sender;
        profitor = paramProfitor;
        _maxPledgeAmount = maxPledgeAmount; 
		_minAmount = minAmount;   
        _maxMiningAmount = maxMiningAmount;
        _maxPreMiningAmount = maxPreMiningAmount;
        _startTime = startTime;
        _endTime = endTime;
        _leftMiningAmount = maxMiningAmount;
    }

    //  token (FISC) -- check is ?---- on 2021-08-25 18:13
    function pledgeToken1( uint256 FiscAmount) public   { 
        require(_leftMiningAmount>0, "less 1 token");
        require(FiscAmount>=_minAmount, "less 2 token");
        require(_totalPledegAmount.add(FiscAmount)<=_maxPledgeAmount, "more token"); 
        require(block.timestamp>=_startTime&&block.timestamp<=_endTime, "is disable");
        uint256 currentFiscAmount=ERC20(_TokenFisc).balanceOf(msg.sender);
        require(currentFiscAmount>=FiscAmount, "currentFiscAmount is less FiscAmount");
 
        if(_orders[msg.sender].isExist==false){
            keys.push(KeyFlag(msg.sender,true));
            size++;
            createOrder( FiscAmount, keys.length.sub(1));
        }else{
            PledgeOrder storage order=_orders[msg.sender];
            order.fiscToken=order.fiscToken.add(FiscAmount);
            keys[order.index].isExist=true;
        }
        _totalPledegAmount=_totalPledegAmount.add(FiscAmount);
        _TokenFisc.safeTransferFrom(msg.sender, address(this), FiscAmount);
    }
 
    //  token (FISC) -- check is ?---- on 2021-08-25 18:13
    function pledgeToken2( uint256 FiscAmount) public   { 
        require(_leftMiningAmount>0, "less 1 token");
        require(FiscAmount>=_minAmount, "less 2 token");
        require(_totalPledegAmount.add(FiscAmount)<=_maxPledgeAmount, "more token"); 
        require(block.timestamp>=_startTime&&block.timestamp<=_endTime, "is disable");
        uint256 currentFiscAmount=ERC20(_TokenFisc).balanceOf(msg.sender);
        require(currentFiscAmount>=FiscAmount, "currentFiscAmount is less FiscAmount");
 
        if(_orders[msg.sender].isExist==false){
            keys.push(KeyFlag(msg.sender,true));
            size++;
            createOrder( FiscAmount, keys.length.sub(1));
        }else{
            PledgeOrder storage order=_orders[msg.sender];
            order.fiscToken=order.fiscToken.add(FiscAmount);
            keys[order.index].isExist=true;
        }
        _totalPledegAmount=_totalPledegAmount.add(FiscAmount);
        
        
        //_TokenFisc.transferFrom(msg.sender, address(this), FiscAmount);
    }
 
    // input profit and profit sharing  -------- check is succ :: 2021-08-25 14:30
    function createOrder(uint256 filAmount,uint256 index) private {
        _orders[msg.sender]=PledgeOrder(
            true,
            filAmount,
            0,
            block.timestamp,
            index
        );
    }
    

 
    // input profit and profit sharing  -------- check is succ :: 2021-08-25 14:08
    function profit( uint256 FilAmount) public onlyProfitor{
        require(_leftMiningAmount>0, "less token");
        require(_totalPledegAmount>0, "no pledge");
        require(FilAmount>0, "profitAmount is zero");
        uint256 currentFilAmount=ERC20(_TokenFil).balanceOf(msg.sender);
        require(currentFilAmount>=FilAmount, "currentFilAmount is less FilAmount");
        uint256 preToken=FilAmount;
        
        for(uint i = 0; i < keys.length; i++) {
            if(keys[i].isExist==true){
                PledgeOrder storage order=_orders[keys[i].key];
                order.filToken=order.filToken.add(order.fiscToken.mul(preToken).div(_totalPledegAmount));
            }
        }
        _leftMiningAmount=_leftMiningAmount.sub(preToken);
        // contract is get preToken ?  ===== wait change
        _TokenFil.safeTransferFrom(address(msg.sender),address(this),preToken);
    }
 
    // -------- check is succ :: 2021-08-25 14:08
    function takeProfit() public {
        require(address(msg.sender) == address(tx.origin), "no contract");
        require(_orders[msg.sender].filToken>0,"filToken is too less");
        uint256 time=block.timestamp;
        uint256 diff=time.sub(_takeProfitTime[msg.sender]);
        require(diff>900,"this operation is too less time");
        PledgeOrder storage order=_orders[msg.sender];
        uint256 takeToken=order.filToken.mul(_precentUp).div(_precentDown);
        order.filToken=order.filToken.sub(takeToken);
        _takeProfitTime[msg.sender]=time;
        _TokenFil.safeTransfer(address(msg.sender),takeToken);
    }
 
    // -------- check is succ :: 2021-08-25 14:18
    function takeToken(uint256 amount) public {
        require(address(msg.sender) == address(tx.origin), "no contract");
        PledgeOrder storage order=_orders[msg.sender];
        require(order.fiscToken>0,"no order");
        require(amount<=order.fiscToken,"take fisctoken is too max");
        _totalPledegAmount=_totalPledegAmount.sub(amount);
        if(order.fiscToken==amount){
            order.fiscToken=0;
            keys[order.index].isExist=false;
        }else{
            order.fiscToken=order.fiscToken.sub(amount);
        }        
        _TokenFisc.safeTransfer(address(msg.sender),amount);
    }
 
    // -------- check is succ :: 2021-08-25 14:23
    function takeAllToken() public {
        require(address(msg.sender) == address(tx.origin), "no contract");
        PledgeOrder storage order=_orders[msg.sender];
        require(order.fiscToken>0,"no order");
        keys[order.index].isExist=false;
        uint256 takeAmount=order.fiscToken;
        order.fiscToken=0;
        _totalPledegAmount=_totalPledegAmount.sub(takeAmount);
        uint256 time=block.timestamp;
        uint256 diff=time.sub(_takeProfitTime[msg.sender]);
        if(diff>=900){
            uint256 profitPart=order.filToken.mul(_precentUp).div(_precentDown);
            order.filToken=order.filToken.sub(profitPart);
            _takeProfitTime[msg.sender]=time;
            _TokenFil.safeTransfer(address(msg.sender),profitPart);
        }
        _TokenFisc.safeTransfer(address(msg.sender),takeAmount);
    }
 
    function getPledgeToken(address tokenAddress) public view returns(uint256) {
        require(address(msg.sender) == address(tx.origin), "no contract");
        PledgeOrder memory order=_orders[tokenAddress];
        return order.fiscToken;
    }
 
    function getfilToken(address tokenAddress) public view returns(uint256) {
        require(address(msg.sender) == address(tx.origin), "no contract");
        PledgeOrder memory order=_orders[tokenAddress];
        return order.filToken;
    }
 
    function getTotalPledge() public view returns(uint256) {
        require(address(msg.sender) == address(tx.origin), "no contract");
        return _totalPledegAmount;
    }
 
    function getPayable(address tokenAddress) private pure returns (address payable) {
        return address(uint168(tokenAddress));
    }
 
    function getTakeProfitTime(address tokenAddress) public view returns(uint256) {
        return _takeProfitTime[tokenAddress];
    }
 
    function changeIsDIS(bool flag) public onlyOwner {
        _isDIS= flag;
    }
 
    function changeOwner(address paramOwner) public onlyOwner {
        require(paramOwner != address(0));
		owner= paramOwner;
    }
 
    function changeProfitor(address paramProfitor) public onlyOwner {
        profitor= paramProfitor;
    }
 
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
 
    modifier onlyProfitor(){
        require(msg.sender == profitor);
    _;
    }
 
    function getOwner() public view returns (address) {
        return owner;
    }
 
    function getProfitor() public view returns (address) {
        return profitor;
    }
 
    function getsize() public view returns (uint256) {
        return size;
    }
 
    function maxPledgeAmount() public view returns (uint256) {
        return _maxPledgeAmount;
    }
 
    function maxMiningAmount() public view returns (uint256) {
        return _maxMiningAmount;
    }
 
    function leftMiningAmount() public view returns (uint256) {
        return _leftMiningAmount;
    }
 
    function minAmount() public view returns (uint256) {
        return _minAmount;
    }
 
    function maxPreMiningAmount() public view returns (uint256) {
        return _maxPreMiningAmount;
    }
 
    function startTime() public view returns (uint256) {
        return _startTime;
    }
 
    function endTime() public view returns (uint256) {
        return _endTime;
    }
 
    function nowTime() public view returns (uint256) {
        return block.timestamp;
    }
 
    function isDIS() public view returns (bool) {
        return _isDIS;
    }
 
}