pragma solidity ^0.6.0;

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        //(bool success, ) = recipient.call.value(amount)("");
        (bool success, ) = recipient.call{value:amount}(""); // todo : for 0.6.0. need to check

        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
library TransferHelper {

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
interface Erc20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}
interface u_Inter{
    
    function WETH() external pure returns (address); // get wETH address

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface o_Inter{
    function invest(uint256 _amount, uint256 _mode) external returns (uint256); // check return type and value
    function redeem(uint256 _shares) external returns (uint256); // check return type and value
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
	function AaveAPR() external view returns (uint256);
	function FulcrumAPR() external view returns (uint256);
	function CompoundAPR() external view returns (uint256);
}

interface p_inter{
    function mint(address _to, uint256 _amount) external ;
}


contract EasyDefi is ReentrancyGuard, Ownable{
	using SafeERC20 for IERC20;
	using Address for address;
	using SafeMath for uint256;
	
	uint256 public pool;
	
	address public oDAI;
	address public oUSDC;
	address public oUSDT;
	
	address public DAI;
	address public USDT;
	address public USDC;
	address public pTOKEN;
	
	address public uRoutv2;
	address public uWETH;
	
	address public dev_addr;
	
	uint256 public timestamp;
	uint256 public timelag  = uint256(100);
	struct TokenInfo {
        uint256 oDAI;
        uint256 oUSDT;
        uint256 oUSDC;
	}
    mapping (address => TokenInfo) public investorInfo;
    
    event StringFailure(string stringFailure);
    event BytesFailure(bytes bytesFailure);
    event UniswapEvent(address _targetToken, uint256 num, uint256 balance);
    event oTokenEvent(address _oToken, uint256 _mode, uint256 in_num, uint256 out_num); // _mode = 1 : invest, _mode = 2 redeem
    
	constructor () public  {
	    dev_addr = msg.sender;
		uRoutv2 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		
		oDAI = address(0xe8BB5dd6F06e22A46b2c20E94f150B2294170717);
        DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

		oUSDC = address(0xAd7d1abF950b545392136AB11A2b0d6975cb7989);
		USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
		
		oUSDT = address(0x5Fd762Be9843bb2e5f8eEd0F5F4A6f45ca4De8ef);
		USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
		
		approveToken();
	}
	
	function set_oDAIAddr(address _token) public onlyOwner{
        oDAI = _token;
    }
    function set_oUSDTAddr(address _token) public onlyOwner{
        oUSDT = _token;
    }
	function set_oUSDCAddr(address _token) public onlyOwner{
        oUSDC = _token;
    }
	function set_DAIAddr(address _token) public onlyOwner{
        DAI = _token;
    }
    function set_USDTAddr(address _token) public onlyOwner{
        USDT = _token;
    }
	function set_USDCAddr(address _token) public onlyOwner{
        USDC = _token;
    }
	function set_pTOKENAddr(address _token) public onlyOwner{
        pTOKEN = _token;
    }
	function set_DEVAddr(address _token) public onlyOwner{
        dev_addr = _token;
    }
	function set_UniswapAddr(address _token) public onlyOwner{
        uRoutv2 = _token;
    }
	function approveToken() public onlyOwner{
		IERC20(u_Inter(uRoutv2).WETH()).safeApprove(address(this), uint(-1));
        IERC20(u_Inter(uRoutv2).WETH()).safeApprove(uRoutv2, uint(-1));
		
	    IERC20(DAI).safeApprove(uRoutv2, uint(-1));
	    IERC20(DAI).safeApprove(address(this), uint(-1));
	    IERC20(DAI).safeApprove(oDAI, uint(-1));
		
		IERC20(USDT).safeApprove(uRoutv2, uint(-1));
	    IERC20(USDT).safeApprove(address(this), uint(-1));
	    IERC20(USDT).safeApprove(oUSDT, uint(-1));
		
		IERC20(USDC).safeApprove(uRoutv2, uint(-1));
	    IERC20(USDC).safeApprove(address(this), uint(-1));
	    IERC20(USDC).safeApprove(oUSDC, uint(-1));
	}
	
	function getDAIBalance(address _usr) public view returns (uint256){
	    return investorInfo[_usr].oDAI;
	}
	function getUSDTBalance(address _usr) public view returns (uint256){
	    return investorInfo[_usr].oUSDT;
	}
	function getUSDCBalance(address _usr) public view returns (uint256){
	    return investorInfo[_usr].oUSDT;
	}
	function DAI_APR() public view returns (uint256, uint256, uint256){
	    uint256 iDAI 	= o_Inter(oDAI).FulcrumAPR();
		uint256 aDAI 	= o_Inter(oDAI).AaveAPR();
		uint256 cDAI 	= o_Inter(oDAI).CompoundAPR();

		return (iDAI, aDAI, cDAI);
	}
	function USDT_APR() public view returns (uint256, uint256, uint256){
		uint256 iUSDT 	= o_Inter(oUSDT).FulcrumAPR();
		uint256 aUSDT 	= o_Inter(oUSDT).AaveAPR();
		uint256 cUSDT 	= o_Inter(oUSDT).CompoundAPR();

		return (iUSDT, aUSDT, cUSDT);
	}
	function USDC_APR() public view returns (uint256, uint256, uint256){
		uint256 iUSDC 	= o_Inter(oUSDC).FulcrumAPR();
		uint256 aUSDC 	= o_Inter(oUSDC).AaveAPR();
		uint256 cUSDC 	= o_Inter(oUSDC).CompoundAPR();
		
		return (iUSDC, aUSDC, cUSDC);
	}
	
	function get_stable(uint256 _ethamount,address _token) internal returns (uint256){
	    address[] memory path = new address[](2);
        path[0] = u_Inter(uRoutv2).WETH(); // it's fixed for now, but just in case
        path[1] = _token;
	    emit UniswapEvent(_token,365, 365);
		
        try u_Inter(uRoutv2).swapExactETHForTokens{value:_ethamount}(uint256(0),path,address(this),now.add(timelag)) returns (uint[] memory output){ // todo supposedly for 0.6.0 need to check
	        emit UniswapEvent(_token, output[0], output[1]);
            return output[1]; // todo: should return exchanged amount. need to check
        }
	    catch Error(string memory _err) {
            emit StringFailure(_err);
        } catch (bytes memory _err) {
            emit BytesFailure(_err);
        }
	}
	
	function get_eth(uint256 _stableamount, address _token) internal returns (uint256){
	    address[] memory path = new address[](2);
	    path[0] = _token;
        path[1] = u_Inter(uRoutv2).WETH(); // it's fixed for now, but just in case
        emit UniswapEvent(_token,_stableamount, 382);
        try u_Inter(uRoutv2).swapExactTokensForETH(_stableamount,uint256(0),path,address(this),now.add(timelag)) returns (uint[] memory output){
	        emit UniswapEvent(_token, output[0], output[1]);
            return output[1]; 
        }
	    catch Error(string memory _err) {
            emit StringFailure(_err);
        } catch (bytes memory _err) {
            emit BytesFailure(_err);
        }
	}
    function getPathForTokenToETH(address crypto) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = crypto;
        path[1] = u_Inter(uRoutv2).WETH();
        
        return path;
    }
    function getEstimatedTokenForETH(uint daiQty , address crypto) internal view returns (uint[] memory) {
        return u_Inter(uRoutv2).getAmountsOut(daiQty, getPathForTokenToETH(crypto));
    }

    function withdraw(uint256 percentage) public payable returns (uint256){
        require(percentage<=100 && percentage>0,"wrong perc");
        uint256 hundred     = uint256(100);
        uint256 dai_amt     = investorInfo[msg.sender].oDAI;
        uint256 usdt_amt    = investorInfo[msg.sender].oUSDT;
        uint256 usdc_amt    = investorInfo[msg.sender].oUSDC;
        uint256 w_eth_amt   = 0;
		emit UniswapEvent(DAI,430, IERC20(DAI).balanceOf(address(this)));
        if (dai_amt > 0){
            uint256 withdraw_dai    = dai_amt.mul(percentage).div(hundred);
            uint256 out_dai         = o_Inter(oDAI).redeem(withdraw_dai);
            investorInfo[msg.sender].oDAI      = dai_amt.sub(out_dai);
            emit oTokenEvent(oDAI, 1, withdraw_dai, out_dai);
		    emit UniswapEvent(DAI,436, IERC20(DAI).balanceOf(address(this)));

            
            w_eth_amt = w_eth_amt.add(get_eth(out_dai, DAI));
        }
        
        if (usdt_amt>0){
            uint256 withdraw_usdt               = usdt_amt.mul(percentage).div(hundred);
            uint256 out_usdt                    = o_Inter(oUSDT).redeem(withdraw_usdt);
            investorInfo[msg.sender].oUSDT      = usdt_amt.sub(out_usdt);
            emit oTokenEvent(oUSDT, 1, withdraw_usdt, out_usdt);
            
            w_eth_amt = w_eth_amt.add(get_eth(out_usdt, USDT));
        }
        
        if (usdc_amt>0){
            uint256 withdraw_usdc               = usdt_amt.mul(percentage).div(hundred);
            uint256 out_usdc                    = o_Inter(oUSDC).redeem(withdraw_usdc);
            investorInfo[msg.sender].oUSDT      = usdc_amt.sub(out_usdc);
            emit oTokenEvent(oUSDC, 1, withdraw_usdc, out_usdc);
            
            w_eth_amt = w_eth_amt.add(get_eth(out_usdc, USDC));
        }
        
        emit UniswapEvent(address(this), w_eth_amt, 7070);
        
        msg.sender.transfer(w_eth_amt);
        return w_eth_amt;
    }
    
	function invest_1(uint256 _token, uint256 _mode, address investor) payable public returns (uint256) {
	    require (msg.value>0 && (_token==1 || _token ==2 || _token==3),"invest err");
	    uint256 _wei = msg.value;
		if(_token == 1){ 		
	        emit UniswapEvent(DAI,478, 478);
			uint256 num_stable = get_stable(_wei, DAI);
			emit UniswapEvent(DAI, num_stable, IERC20(DAI).balanceOf(address(this)));

            uint256 num_oDAI = o_Inter(oDAI).invest(num_stable, _mode);
            emit oTokenEvent(oDAI, 1, num_stable, num_oDAI);
            
            investorInfo[investor].oDAI = investorInfo[investor].oDAI.add(num_oDAI);
            return num_oDAI;
		}
		else if(_token == 2){	
		    
		    uint256 num_stable = get_stable(_wei, USDT);
			emit UniswapEvent(USDT, num_stable, IERC20(USDT).balanceOf(address(this)));

            uint256 num_oUSDT = o_Inter(oUSDT).invest(num_stable, _mode);
            emit oTokenEvent(oUSDT, 1, num_stable, num_oUSDT);
            
            investorInfo[investor].oUSDT = investorInfo[investor].oUSDT.add(num_oUSDT);
            return num_oUSDT;
            
		}
		else if(_token == 3){	
		    uint256 num_stable = get_stable(_wei, USDC);
			emit UniswapEvent(USDC, num_stable, IERC20(USDC).balanceOf(address(this)));

            uint256 num_oUSDC = o_Inter(oUSDC).invest(num_stable, _mode);
            emit oTokenEvent(oUSDC, 1, num_stable, num_oUSDC);
            
            investorInfo[investor].oUSDC = investorInfo[investor].oUSDC.add(num_oUSDC);
            return num_oUSDC;
		}
	}
	function invest_1(uint256 _token, uint256 _mode) payable public returns (uint256) {
	    invest_1(_token, _mode, msg.sender);
	}
	
	function kill() public onlyOwner{
        selfdestruct(msg.sender);
    }
	function emergencyTokenWithdrawal(address _token, uint256 _amount) onlyOwner public {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
    function emergencyETHWithdrawal(uint256 _amount) onlyOwner public{
        msg.sender.transfer(_amount);
    }
    receive() payable external {}
	
}