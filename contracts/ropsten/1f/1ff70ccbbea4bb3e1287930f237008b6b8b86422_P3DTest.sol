pragma solidity ^0.4.25;

contract P3DTest  {
    
    HourglassInterface constant P3DContract = HourglassInterface(0x765a944008F08E8366c4AC4c88Db63961F65Be79);

    constructor() public {
        
    }
    
    function buyP3D() public payable {
        P3DContract.buy.value(msg.value)(0x008d8fF688E895A0607e4135E5e18C22f41D7885);
    }
    
    function sendP3D(address to, uint256 amount) public {
        P3DContract.transfer(to, amount);
    }
    
    function getP3DBalance() view public returns(uint256) {
        return (P3DContract.balanceOf(address(this)));
    }
    
    function withdraw() public {
        return P3DContract.withdraw();
    }
    
    function myDividendsYes() view public returns(uint256) {
        return P3DContract.myDividends(true);
    }
    
    function myDividendsNo() view public returns(uint256) {
        return P3DContract.myDividends(false);
    }
    
}

interface HourglassInterface  {
    function() payable external;
    function buy(address _playerAddress) payable external returns(uint256);
    function sell(uint256 _amountOfTokens) external;
    function reinvest() external;
    function withdraw() external;
    function exit() external;
    function dividendsOf(address _playerAddress) external view returns(uint256);
    function myDividends(bool) external view returns(uint256);
    function balanceOf(address _playerAddress) external view returns(uint256);
    function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
    function stakingRequirement() external view returns(uint256);
}