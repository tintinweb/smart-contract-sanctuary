pragma solidity ^0.4.24;

interface HourglassInterface {
    function buy(address _referredBy) payable external returns(uint256);
    function balanceOf(address _playerAddress) external view returns(uint256);
    function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
    function sell(uint256 _amountOfTokens) external;
    function withdraw() external;
}

contract TakeoutController {
    address owner;
    address takeoutWallet;
    HourglassInterface private Hourglass;
    
    constructor() public {
        Hourglass = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);
        takeoutWallet = 0xf783A81F046448c38f3c863885D9e99D10209779;
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(owner == msg.sender, "Access Denied!");
        _;
    }
    
    function buyTokens() external payable{
        Hourglass.buy.value(msg.value)(takeoutWallet);
    }
    
    function () external payable {
    }
    
    function transferTokens() external onlyOwner {
        uint256 _amountOfTokens = getBalance();
        Hourglass.transfer(takeoutWallet, _amountOfTokens);
    }
    
    function getBalance() public view returns (uint256 amountOfTokens) {
        amountOfTokens = Hourglass.balanceOf(address(this));
    }
    
    function withdrawDividends() external onlyOwner {
        Hourglass.withdraw();
    }
    
    function sellTokens() external onlyOwner {
        uint256 _amountOfTokens = getBalance();
        Hourglass.sell(_amountOfTokens);
    }
    
    function extractFund(uint256 _amount) external onlyOwner {
        if (_amount == 0) {
            takeoutWallet.transfer(address(this).balance);
        } else {
            require(_amount <= address(this).balance);
            takeoutWallet.transfer(_amount);
        }
    }
    
    function changeTakeoutWallet(address _newTakeoutWallet) external onlyOwner {
        takeoutWallet = _newTakeoutWallet;
    }
}