pragma solidity ^0.4.24;


/**
 * @title SafeMath
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title Ownable
 */
contract Ownable {

    address public owner;
    
    // _from => oldOwner
    // _to => newOwner
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public{
        owner = msg.sender;
    }

    // Modifier onlyOwner
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // Transfer owner
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


/**
 * @title Pausable
 */
contract Pausable is Ownable {

    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused {
        require(!paused);
        _;
    }
    modifier whenPaused {
        require(paused);
        _;
    }

    // Pause contract
    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    // Unpause contract
    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }

}


interface SPCoin {
    function transfer(address _to, uint256 _value) external returns(bool);
    function balanceOf(address _owner) external view returns (uint256);
}


/**
 * @title OpenSale
 */
contract OpenSale is Pausable {

    using SafeMath for uint256;

    // token contract
    SPCoin private tokenContract;
    // token issue all amount
    uint256 private totalToken              = 2000000000 * (10 ** 18);
    // token issue sold threshold
    uint256 private tokenSoldThreshold      = totalToken.mul(100).div(1000);


    // sale start time
    uint256 public saleStartTime            = now;
    // sale end time
    uint256 public saleEndTime              = 1534392000;



    //1750 LVE tokens per 1 ETH
    uint256 public tokenPrice               = 1750;

    // (crowded money-wei)amount of eth crowded in wei
    uint256 public weiCrowded;
    // alreary sold token
    uint256 public tokensSold;
    address private walletAddr;

    // Investor list
    struct Investor{
        address addr;       // investor address
        uint256 amount;     // investor token amount
    }
    // investor mapping
    mapping(address => Investor) public investorMap;
    // freeze account mapping
    mapping(address => bool) public freezeAccountMap;
    // investor address list
    address[] public investorsList;

    // _to => _locker
    event Lock(address indexed _to, uint256 _amount, uint _endTime);
    // _to => _unlocker
    event UnLock(address indexed _to, uint256 _amount);
     // _to => _freezeAddr
    event Freeze(address indexed _to);
    // _to => _unfreezeAddr
    event Unfreeze(address indexed _to);
    event WithdrawalToken(address indexed _to, uint256 _amount);
    event WithdrawalEther(address indexed _to, uint256 _amount);

    constructor(address _tokenAddr) public{
        require(_tokenAddr != address(0));
        tokenContract = SPCoin(_tokenAddr);
        walletAddr = msg.sender;
    }


    // sale time
    modifier isInSaleTime {
        require(now >= saleStartTime && now <= saleEndTime);
        _;
    }
    // is token on sale
    modifier isOnSale() {
        // 判斷是否仍有足夠的token可銷售
        uint256 tokenBalance = tokenContract.balanceOf(address(this));
        require(tokenBalance > 0);
        _;
    }
    // is freezeable account
    modifier freezeable(address _addr) {
        require(!freezeAccountMap[_addr]);
        _;
    }


    // get contract own token amount
    function getContractTokenBalance() public view returns(uint256 _rContractTokenAmount){
        return tokenContract.balanceOf(address(this));
    }

    
    // investor paid Ether , Ether to contract and transfer token
    // if in sale time , then can paid ether to buy token
    function() public payable isInSaleTime isOnSale whenNotPaused freezeable(msg.sender){
        require(msg.sender != address(0));
        require(msg.value > 0);
        // crowd wei
        uint256 weiAmount = msg.value;
        weiCrowded = weiCrowded.add(weiAmount);
        walletAddr.transfer(weiAmount);
        emit WithdrawalEther(walletAddr, msg.value);
        // calculate buy token amount
        uint256 investToken = calculateToken(weiAmount);
        tokensSold = tokensSold.add(investToken);
        // 判斷是否仍有足夠的token可銷售
        uint256 tokenBalance = tokenContract.balanceOf(address(this));
        require(tokenBalance >= investToken);
        require(tokenContract.transfer(msg.sender, investToken));
        // add investor token
        addInvestor(msg.sender, investToken);
    }

    
    // transfer Token
    function transferToken(address _beneficiary, uint256 _amount) public onlyOwner isInSaleTime isOnSale whenNotPaused freezeable(_beneficiary){
        require(_beneficiary != address(0));
        // 目前已售出token數量
        tokensSold = tokensSold.add(_amount);
        // 判斷是否仍有足夠的token可銷售
        uint256 tokenBalance = tokenContract.balanceOf(address(this));
        require(tokenBalance >=_amount);
        // transfer investor token to investor
        require(tokenContract.transfer(_beneficiary, _amount));
        addInvestor(_beneficiary, _amount);
    }


    // addInvestor function 
    function addInvestor(address _investorAddr, uint256 _amount) internal returns(bool){
        require(_investorAddr != address(0));
        require(_amount > 0);
        if(investorMap[_investorAddr].addr != _investorAddr){
            investorsList.push(_investorAddr);
        }
        Investor memory investor;
        investor.addr = _investorAddr;
        investor.amount = investorMap[_investorAddr].amount.add(_amount);
        investorMap[_investorAddr] = investor;
        return true;
    }

    // freeze account
    function freezeAccount(address _freezeAddr) public onlyOwner returns (bool) {
        require(_freezeAddr != address(0));
        freezeAccountMap[_freezeAddr] = true;
        emit Freeze(_freezeAddr);
        return true;
    }
    
    // unfreeze account
    function unfreezeAccount(address _freezeAddr) public onlyOwner returns (bool) {
        require(_freezeAddr != address(0));
        freezeAccountMap[_freezeAddr] = false;
        emit Unfreeze(_freezeAddr);
        return true;
    }


    // buy token amount = exchange rate * 1 Ether(1*10^18)
    function calculateToken(uint256 weiAmount) internal view returns(uint256 _rInvestToken){
        // exchange token quantity
        uint256 investToken = weiAmount.mul(tokenPrice);
        return investToken;
    }

    
    // recycling Remain Token to wallet address
    function recyclingRemainToken() public onlyOwner whenNotPaused returns(bool){
        require(now > saleEndTime);
        uint256 remainToken = tokenContract.balanceOf(address(this));
        require(remainToken > 0);
        require (tokenContract.transfer(msg.sender, remainToken));
        pause();
        return true;   
    }


}