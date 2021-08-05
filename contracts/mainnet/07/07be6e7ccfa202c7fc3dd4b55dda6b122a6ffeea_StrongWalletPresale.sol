/**
 *Submitted for verification at Etherscan.io on 2021-01-13
*/

pragma solidity ^0.6.12;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
interface ERC20 {
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
}

abstract contract ProxyKyberSwap {
    function getExpectedRate(
        ERC20 src,
        ERC20 dest,
        uint srcQty
    ) virtual external view returns (uint256 expectedRate, uint256 worstRate);
}
contract StrongWalletPresale {
    using SafeMath for uint256;
    address payable public owner;
    uint public presaleAmount = 3000000 ether;
    ProxyKyberSwap public proxyKyberSwap = ProxyKyberSwap(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    ERC20 public STRONG = ERC20(0xf217f7df49f626f83f40D7D5137D663B1ec4EE6E);
    ERC20 constant public ETH_TOKEN_ADDRESS = ERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    ERC20 constant public USDT_TOKEN_ADDRESS = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    uint[] rates = [160, 150, 135, 125, 115, 100]; // decimal = 3
    mapping(address => uint) public sellers;
    // event
    event DepositETH(address receiver, uint amount, uint amountStrong);
    event DepositUSDT(address receiver, uint amount, uint amountStrong);
    event DepositETHWithSeller(address receiver, uint amount, uint amountStrong, address _seller);
    event DepositUSDTWithSeller(address receiver, uint amount, uint amountStrong, address _seller);
    event LogWithdrawal(address _to, uint _amountStrong);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getRate(uint _usdtAmount) public view returns(uint _rate) {
        if(_usdtAmount <= 100 ether) return rates[0];
        else if(_usdtAmount <= 1000 ether) return rates[1];
        else if(_usdtAmount <= 5000 ether) return rates[2];
        else if(_usdtAmount <= 10000 ether) return rates[3];
        else if(_usdtAmount <= 50000 ether) return rates[4];
        else return rates[5];
    }
    function USDT2Strong(uint _usdtAmount) public view returns(uint _amountStrong) {
        uint rate = getRate(_usdtAmount);
        return _usdtAmount.mul(1000).div(rate);
    }
    function ETH2USDT() public view returns (uint _amountUsdt){
        uint256 expectedRate;
        (expectedRate,) = proxyKyberSwap.getExpectedRate(ETH_TOKEN_ADDRESS, USDT_TOKEN_ADDRESS, 1 ether);
        return expectedRate;
    }
    function ETH2STRONG(uint _amountETH) public view returns(uint _amountStrong) {
        uint256 expectedRate = ETH2USDT();
        uint256 usdtAmount = expectedRate.mul(_amountETH).div(1 ether);
        return USDT2Strong(usdtAmount);
    }
    function depositEth() public payable {
        uint256 amountStrong = ETH2STRONG(msg.value);
        owner.transfer(msg.value);
        STRONG.transfer(msg.sender, amountStrong);
        emit DepositETH(msg.sender, msg.value, amountStrong);
    }
    function depositUSDT(uint256 _amountUsdt) public {
        uint256 amountStrong = USDT2Strong(_amountUsdt);
        require(USDT_TOKEN_ADDRESS.transferFrom(msg.sender, owner, _amountUsdt));
        STRONG.transfer(msg.sender, amountStrong);
        emit DepositUSDT(msg.sender, _amountUsdt, amountStrong);
    }

    function depositEthWithSeller(address _seller) public payable {
        require(msg.sender != _seller);
        depositEth();
        uint selledAmout = sellers[_seller];
        uint bonusPercent = selledAmout > 0 ? 20 : 50;
        uint amountStrong = ETH2STRONG(msg.value);
        uint bonusAmount = amountStrong.mul(bonusPercent).div(1000);
        STRONG.transfer(_seller, bonusAmount);
        sellers[_seller] += amountStrong;
        emit DepositETHWithSeller(msg.sender, msg.value, amountStrong, _seller);
    }
    function depositUSDTWithSeller(uint256 _amountUsdt, address _seller) public {
        require(msg.sender != _seller);
        depositUSDT(_amountUsdt);
        uint selledAmout = sellers[_seller];
        uint bonusPercent = selledAmout > 0 ? 20 : 50;
        uint amountStrong = USDT2Strong(_amountUsdt);
        uint bonusAmount = amountStrong.mul(bonusPercent).div(1000);
        STRONG.transfer(_seller, bonusAmount);
        sellers[_seller] += amountStrong;
        emit DepositUSDTWithSeller(msg.sender, _amountUsdt, amountStrong, _seller);
    }
    /**
    * @dev Withdraw the amount of token that is remaining in this contract.
    * @param _address The address of EOA that can receive token from this contract.
    */
    function withdraw(address _address) public onlyOwner {
        uint tokenBalanceOfContract = getRemainingToken();
        STRONG.transfer(_address, tokenBalanceOfContract);
        emit LogWithdrawal(_address, tokenBalanceOfContract);
    }

    /**
    * @dev Get the remaining amount of token user can receive.
    * @return Uint256 the amount of token that user can reveive.
    */
    function getRemainingToken() public view returns (uint256) {
        return STRONG.balanceOf(address(this));
    }
}