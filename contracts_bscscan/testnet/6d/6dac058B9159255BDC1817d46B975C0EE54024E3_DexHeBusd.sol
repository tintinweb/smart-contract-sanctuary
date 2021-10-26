pragma solidity ^0.8.0;
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}
interface IBEP20 { 
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
	function mint(address account, uint256 amount) external returns (bool);
	function burn(address account, uint256 amount) external returns (bool);
	function addOperator(address minter) external returns (bool);
	function removeOperator(address minter) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval( address indexed owner, address indexed spender, uint256 value );
}
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        // uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeBEP20: ERC20 operation did not succeed");
        }
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
} 
contract DexHeBusd {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;
    IBEP20 public heroesToken;
    IBEP20 public busdToken;
    constructor( address _heroesToken, address _busdToken ) {
        heroesToken = IBEP20(_heroesToken); // Token Heroes
        busdToken = IBEP20(_busdToken); // Token BUSD
        id[_heroesToken] = 1; // Swap HE
        id[_busdToken] = 2; // Swap Busd
	}
    mapping(address => uint256) public id;
    event SwapHeToBusd(
        address Owner,
        uint256 balance,
        uint256 timeSwap
    );
    event SwapBusdToHe(
        address Owner,
        uint256 balance,
        uint256 timeSwap
    );
    function getPriceHe() public view returns(uint256){
        uint256 balanceHe = heroesToken.balanceOf(address(this));
        uint256 balanceBusd = busdToken.balanceOf(address(this));
        uint256 price = balanceBusd.mul(1e18).div(balanceHe);
        return price;
    }
    function getBalanceReceive(address _token, uint256 _amount) public view returns(uint256){
        uint256 balanceHe = heroesToken.balanceOf(address(this));
        uint256 balanceBusd = busdToken.balanceOf(address(this));
        uint256 balanceReceive = 0;
        require( (balanceHe > 0) && (balanceBusd > 0), "amount = 0");
         uint256 idToken = id[_token];
        require(idToken != 0, "Token addresses are not accepted");
        if(idToken == 1){
            balanceReceive = balanceBusd.mul(_amount).div(_amount.add(balanceHe));
        }
        if(idToken == 2){
            balanceReceive = balanceHe.mul(_amount).div(_amount.add(balanceBusd));
        }
        return balanceReceive;
    }
    function swapToken(address _token, uint256 _amount) public {
        uint256 balanceHe = heroesToken.balanceOf(address(this));
        uint256 balanceBusd = busdToken.balanceOf(address(this));
        require( (balanceHe > 0) && (balanceBusd > 0), "amount = 0");
        uint256 idToken = id[_token];
        require(idToken != 0, "Token addresses are not accepted");
        if(idToken == 1){
            swapHeToBusd(_amount, balanceHe, balanceBusd);
        }
        if(idToken == 2){
            swapBusdToHe(_amount,  balanceHe, balanceBusd);
        }

    }   
    function swapHeToBusd(uint256 _amount, uint256 _amountHe, uint256 _amountBusd) internal {
        uint256 balanceAccount = heroesToken.balanceOf(address(msg.sender));
        require(balanceAccount >= _amount, "Insufficient balance");
        heroesToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 balanceReceive = _amountBusd.mul(_amount).div(_amount.add(_amountHe));
        safeBUSDTransfer(msg.sender, balanceReceive);    
    }
    function swapBusdToHe(uint256 _amount, uint256 _amountHe, uint256 _amountBusd) internal {
        uint256 balanceAccount = busdToken.balanceOf(address(msg.sender));
        require(balanceAccount >= _amount, "Insufficient balance");
        busdToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 balanceReceive = _amountHe.mul(_amount).div(_amount.add(_amountBusd));
        safeHETransfer(msg.sender, balanceReceive);
    }
    function safeHETransfer(address _to, uint256 _amount) internal {
        uint256 HEBalance = heroesToken.balanceOf(address(this));
        uint256 amountTransfer = _amount > HEBalance ? HEBalance : _amount;
        heroesToken.transfer(_to, amountTransfer);
        emit SwapHeToBusd(
            msg.sender,
            amountTransfer,
            block.timestamp
        );
    }
    function safeBUSDTransfer(address _to, uint256 _amount) internal {
        uint256 BusdBalance = busdToken.balanceOf(address(this));
        uint256 amountTransfer = _amount > BusdBalance ? BusdBalance : _amount;
        busdToken.transfer(_to, amountTransfer);
        emit SwapBusdToHe(
            msg.sender,
            amountTransfer,
            block.timestamp
        );
    }
}