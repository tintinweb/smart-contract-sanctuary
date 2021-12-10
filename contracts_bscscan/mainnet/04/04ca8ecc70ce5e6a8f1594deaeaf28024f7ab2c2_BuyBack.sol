/**
 *Submitted for verification at BscScan.com on 2021-12-10
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
}

pragma solidity >=0.6.2;
//pragma experimental ABIEncoderV2;

contract BuyBack is Ownable {
    using SafeMath for uint256;

    IPancakeRouter public pancakeRouter;

    // xos->usdt
    address[] public path = [0x4BacB027E0bf98025d8EC91493F6512b9F0FA0dc,0x55d398326f99059fF775485246999027B3197955];

    struct P2PQueue {
        address buyer;           // Address buyer
        address seller;          // Address seller
        uint256 amountXOS;
        uint256 amountSwapToken;
        uint256 price;
        uint256 createDate;
    }
    
    P2PQueue[] public queue;
    
    P2PQueue[] public history;

    IBEP20 public xosToken;
    IBEP20 public swapToken;

    address public masterChef = 0xE399d7504310B84D38eFD56Cf8A29b38801D6449;

    modifier onlyMasterChef() {
        require(msg.sender == address(masterChef), "Only MasterChef can call this function");
        _;
    }

    function setMasterChef(address _masterChef) external onlyOwner {
        masterChef = _masterChef;
    }

    constructor (IBEP20 _xosToken, IBEP20 _swapToken, address _pancakeRouter) public {
        xosToken = _xosToken;
        swapToken = _swapToken;
		pancakeRouter = IPancakeRouter(_pancakeRouter);
	}

    function setPancakeRouter(address _pancakeRouter) public{
        pancakeRouter = IPancakeRouter(_pancakeRouter);
    }

    function setXosToken(IBEP20 _xosToken) public{
        xosToken = _xosToken;
    }

    function setSwapToken(IBEP20 _swapToken) public{
        swapToken = _swapToken;
    }

    function setPath(address[] memory _path) public{
        path = _path;
    }

    function getAllQueue() public view returns (address[] memory,address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory) {
        address[] memory buyer = new address[](queue.length);
        address[] memory seller = new address[](queue.length);
        uint256[] memory amountXOS = new uint256[](queue.length);
        uint256[] memory amountSwapToken = new uint256[](queue.length);
        uint256[] memory price = new uint256[](queue.length);
        uint256[] memory createDate = new uint256[](queue.length);
        for(uint i=0;i<queue.length;i++){
            buyer[i] = queue[i].buyer;
            seller[i] = queue[i].seller;
            amountXOS[i] = queue[i].amountXOS;
            amountSwapToken[i] = queue[i].amountSwapToken;
            price[i] = queue[i].price;
            createDate[i] = queue[i].createDate;
        }
        return (buyer,seller,amountXOS,amountSwapToken,price,createDate);
    }

    function getAllHistory() public view returns (address[] memory,address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory) {
        address[] memory buyer = new address[](queue.length);
        address[] memory seller = new address[](queue.length);
        uint256[] memory amountXOS = new uint256[](queue.length);
        uint256[] memory amountSwapToken = new uint256[](queue.length);
        uint256[] memory price = new uint256[](queue.length);
        uint256[] memory createDate = new uint256[](queue.length);
        for(uint i=0;i<queue.length;i++){
            buyer[i] = history[i].buyer;
            seller[i] = history[i].seller;
            amountXOS[i] = history[i].amountXOS;
            amountSwapToken[i] = history[i].amountSwapToken;
            price[i] = history[i].price;
            createDate[i] = history[i].createDate;
        }
        return (buyer,seller,amountXOS,amountSwapToken,price,createDate);
    }

    function getLastHistory(uint cnt) public view returns (address[] memory,address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        address[] memory buyer = new address[](cnt);
        address[] memory seller = new address[](cnt);
        uint256[] memory amountXOS = new uint256[](cnt);
        uint256[] memory amountSwapToken = new uint256[](cnt);
        uint256[] memory price = new uint256[](cnt);
        uint256[] memory createDate = new uint256[](cnt);

        uint j=0;
        uint i=history.length-cnt;
        if(i<0)
            i=0;
        for(i;i<history.length;i++){
            buyer[j] = history[i].buyer;
            seller[j] = history[i].seller;
            amountXOS[j] = history[i].amountXOS;
            amountSwapToken[j] = history[i].amountSwapToken;
            price[j] = history[i].price;
            createDate[j] = history[i].createDate;
            j++;
        }
        return (buyer,seller,amountXOS,amountSwapToken,price,createDate);
    }
    

    function getAmountOuts(uint256 amount) public view returns (uint){
        uint256 totalOut = pancakeRouter.getAmountsOut(amount,path)[1];
        return totalOut;
    }

    function saveQueueByContract(address sellerAdd,uint256 totalXOSParam) public onlyMasterChef{

        P2PQueue memory p2p;
        p2p.seller = sellerAdd;
        p2p.amountXOS = totalXOSParam;
        p2p.amountSwapToken = getAmountOuts(totalXOSParam);
        p2p.createDate = block.timestamp;
        //price in swapToken
        p2p.price = p2p.amountSwapToken/p2p.amountXOS;
        queue.push(p2p);
    }

    function getXOSBal() public view returns (uint256){
        return xosToken.balanceOf(msg.sender);
    }

    function saveQueue(uint256 totalXOSParam) public{

        require(xosToken.balanceOf(msg.sender) < totalXOSParam, 'Address: insufficient balance');
        xosToken.transfer(address(this), totalXOSParam);

        P2PQueue memory p2p;
        p2p.seller = address(msg.sender);
        p2p.amountXOS = totalXOSParam;
        p2p.amountSwapToken = getAmountOuts(totalXOSParam);
        p2p.createDate = block.timestamp;
        //price in swapToken
        p2p.price = p2p.amountSwapToken/p2p.amountXOS;
        queue.push(p2p);
    }

    function updateQueue(uint256 totalXOSParam) public{
        P2PQueue[] storage p2pArray = queue;
        uint256 transXOS = 0; 
        for(uint i=0;i<p2pArray.length;i++){
            P2PQueue storage p2p = queue[i];
            p2p.buyer = msg.sender;
            transXOS = transXOS + p2p.amountXOS;
            if(transXOS<=totalXOSParam){
                savetrans();
            }else if(transXOS>=totalXOSParam){
                break;
            }
        }
    }

    function savetrans() internal{
        P2PQueue storage p2p = queue[0];
       
        require(swapToken.balanceOf(msg.sender) < p2p.amountXOS, 'Address: insufficient balance');
        require(xosToken.balanceOf(address(this)) < p2p.amountSwapToken, 'Address: insufficient balance');
         //transfer busd to seller
        swapToken.transfer(address(p2p.seller), p2p.amountSwapToken);
        //transfer xos to getLeaderByUser
        xosToken.transferFrom(address(this),address(p2p.buyer), p2p.amountXOS);
        //add to history
        history.push(p2p);
        //remove from queue
        delete queue[0];
    }
}