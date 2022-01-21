/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: GPL-v3.0

pragma solidity >=0.4.0;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity ^0.6.2;

library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.0;


library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

pragma solidity >=0.4.0;

contract Context {

    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity >=0.4.0;


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity >=0.5.16;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.6;
interface IPancakeRouter{
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

pragma solidity >=0.6.2;
interface ICloudEco{
    function depositFromSellback(uint256 _pid,uint256 _amount, address _referrer, address _seller) external;
}

pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;

contract SellBack is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    IPancakeRouter public pancakeRouter;

    ICloudEco public cloudEco;

    // xos->usdt
    address[] public path = [0x55d398326f99059fF775485246999027B3197955,0x4BacB027E0bf98025d8EC91493F6512b9F0FA0dc];

    struct P2PQueue {
        address buyer;           // Address buyer
        address seller;          // Address seller
        uint256 amountXOS;
        uint256 amountUSDT;
        uint256 price;
        uint256 createDate;
        address referral;
    }
    
    P2PQueue[] public queue;
    
    P2PQueue[] public history;

    IBEP20 public xosToken;
    IBEP20 public usdtToken;
    IBEP20 public xosusdtToken;

    uint256 public markup = 110;
    uint256 public minAmtLP = 90;

    address public masterChef = 0x185ED145623FE913c826036e49c39CEaD8E61Adb;

    mapping(address => bool) public smartChef;
    
    modifier onlyMasterChef() {
        require(msg.sender == address(masterChef), "Only MasterChef can call this function");
        _;
    }

    modifier onlySpAdd() {
        require(smartChef[msg.sender] == true, " ");
        _;
    }

    function addSpAdd(address _spAdd) external onlyOwner {
        smartChef[_spAdd] = true;
    }

    function removeSpAdd(address _spAdd) external onlyOwner {
        delete smartChef[_spAdd];
    }

    function setMasterChef(address _masterChef) external onlyOwner {
        masterChef = _masterChef;
    }

    constructor (IBEP20 _xosToken, IBEP20 _usdtToken, address _pancakeRouter, address _cloudeco,IBEP20 _xosusdtToken) public {
        xosToken = _xosToken;
        usdtToken = _usdtToken;
		pancakeRouter = IPancakeRouter(_pancakeRouter);
        cloudEco = ICloudEco(_cloudeco);
        xosusdtToken = _xosusdtToken;
	}

    function setCloudEco(address _cloudeco) public{
        cloudEco = ICloudEco(_cloudeco);
    }

    function setPancakeRouter(address _pancakeRouter) public{
        pancakeRouter = IPancakeRouter(_pancakeRouter);
    }

    function setXosToken(IBEP20 _xosToken) public{
        xosToken = _xosToken;
    }

    function setSwapToken(IBEP20 _usdtToken) public{
        usdtToken = _usdtToken;
    }

    function setPath(address[] memory _path) public{
        path = _path;
    }

    function setMarkup(uint256 _markup) public{
        markup = _markup;
    }

    function setMinAmt(uint256 _minAmtLP) public{
        minAmtLP = _minAmtLP;
    }

    function getAllQueue() public view returns (P2PQueue[] memory) {
        return queue;
    }

    function getAllHistory() public view returns (P2PQueue[] memory) {
        return history;
    }

    function getLastHistory(uint cnt) public view returns (P2PQueue[] memory){
        P2PQueue[] memory p2p= new P2PQueue[](cnt);
        uint j=0;
        uint i=history.length-cnt;
        if(i<0)
            i=0;
        for(i;i<history.length;i++){
            p2p[j] = history[i];
            j++;
        }
        return p2p;
    }

    function getAmountOuts(uint256 amount) public view returns (uint){
        uint256 totalOut = pancakeRouter.getAmountsOut(amount,path)[1];
        return totalOut;
    }

    function intSaveQueue(address sellerAdd,uint256 totalXOSParam,uint256 _amountUSDT,address _referral)  internal{
        P2PQueue memory p2p;
        p2p.seller = sellerAdd;
        p2p.amountXOS = totalXOSParam;
        p2p.amountUSDT = _amountUSDT;
        p2p.createDate = block.timestamp;
        //price in swapToken
        p2p.price = p2p.amountUSDT/p2p.amountXOS;
        p2p.referral = _referral;
        
        //push p2p in array
        uint index = 0;
        bool update = false;
        for(uint i=0;i<queue.length;i++){
            if(queue[i].seller==address(0)){
                index = i;
                update = true;
                break;
            }   
        }
        if(update){
            queue[index] = p2p;
        }else{
            queue.push(p2p);
        }
    }

    function saveQueueByContract(address sellerAdd,uint256 _amount,address _referral) public onlyMasterChef{
        //convert 50% to xos
        uint256 amountUSDT = _amount/2; 
        uint256 amountXOS = getAmountOuts(amountUSDT)*markup/100;
        intSaveQueue(sellerAdd,amountXOS,amountUSDT,_referral);
    }

    function saveQueue(uint256 _amount,address _referral) public{
        //transfer usdt
        usdtToken.safeTransferFrom(address(msg.sender),address(this), _amount);

        //convert 50% to xos
        uint256 amountUSDT = _amount/2; 
        uint256 amountXOS = getAmountOuts(amountUSDT)*markup/100;

        intSaveQueue(address(msg.sender),amountXOS,amountUSDT, _referral);
    }

    function updateQueue(uint256 totalXOSParam) public onlySpAdd{
        P2PQueue[] storage p2pArray = queue;
        uint256 transXOS = totalXOSParam; 
        for(uint i=0;i<p2pArray.length;i++){
            P2PQueue storage p2p = queue[i];
            p2p.buyer = msg.sender;
            if(p2p.amountXOS<=transXOS && transXOS>0){
                transXOS = transXOS - p2p.amountXOS;
                savetrans(p2p);
                delete queue[i];
            }else{
                break;
            }
        }
        //reset queue
        resetQueue();
    }

    function resetQueue() internal{
        uint gap = 0;
        //define gap
        for (uint i = 0; i < queue.length-1; i++) {
            if(queue[gap].seller == address(0)){
                gap++;
                continue;
            }else{
                break;
            }
        }
        if(gap>0){
            for (uint i = 0; i < queue.length - gap; i++) {
                queue[i] = queue[i + gap];
            }
            for(uint i=0;i<gap;i++){
                delete queue[queue.length-(gap-i)];
            }
            
        }
    }

    function getLPPrice(address lp) public view returns (uint256){
        uint256 totalSupply = IPancakePair(lp).totalSupply();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IPancakePair(lp).getReserves();
        uint256 price = reserve1*2/totalSupply; 
        return price;
    }

    function savetrans(P2PQueue storage p2p) internal{
        //transfer usdt to buyer
        usdtToken.safeTransfer(address(msg.sender), p2p.amountUSDT);
        //transfer xos to smart contract
        xosToken.safeTransferFrom(address(msg.sender),address(this), p2p.amountXOS);
        //add liquidity
        //approve(pancakeRouter, tokenAmount);
        //(uint amountA, uint amountB,uint liquidity) = pancakeRouter.addLiquidity(address(xosToken),address(usdtToken),p2p.amountXOS,p2p.amountUSDT,p2p.amountXOS*minAmtLP/100,p2p.amountUSDT*minAmtLP/100,address(this),block.timestamp+60);
        
        //transfer
        xosToken.safeTransfer(address(cloudEco), p2p.amountXOS);
        usdtToken.safeTransfer(address(cloudEco), p2p.amountUSDT);
        //add cloud eco
        uint256 priceLp = getLPPrice(address(xosusdtToken));
        uint256 amtcake = p2p.amountUSDT*2/priceLp;
        cloudEco.depositFromSellback(0,amtcake,address(p2p.referral),address(p2p.seller));
        //add to history
        history.push(p2p);
    }

    function emergencyTokenWithdraw(IBEP20 token,uint256 _amount) public onlyOwner {
        require(_amount < token.balanceOf(address(this)), 'not enough token');
        token.safeTransfer(address(msg.sender), _amount);
    }

    function deleteQueue(uint256 index) public onlyOwner {
         delete queue[index];
         resetQueue();
    }
}