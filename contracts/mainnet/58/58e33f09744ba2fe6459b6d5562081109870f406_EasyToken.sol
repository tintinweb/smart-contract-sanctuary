/**
 *Submitted for verification at Etherscan.io on 2020-12-11
*/

//"SPDX-License-Identifier: UNLICENSED"sdgeryjewrtrwedcvdfbasAFwe

//frgwert34rgvfev

//frgwert34rgvfev
pragma solidity ^0.6.0;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV

//frgwert34rgvfev9[4R]
abstract contract Context {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUA

//frgwert34rgvfevCV9[4R]
    function _msgSender() internal view virtual returns (address payable) {////////sdfert/weh98pWSEI;Jdsewr78

//frgwert34rgvfev039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        return msg.sender;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    function _msgData() internal view virtual returns (bytes memory) {////////sdfert/weh98pWSEI;Jdsewr78

//frgwert34rgvfev039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        this;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HE

//frgwert34rgvfevwnqdNBHSUACV9[4R]
        return msg.data;}}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
interface IERC20 {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    function totalSupply() external view returns (uint256);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
    function balanceOf(address account)external view returns (uint256);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70

//frgwert34rgvfevwgQY3HEwnqdNBHSUACV9[4R]
    function transfer(address recipient, uint256 amount) external returns (bool);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    function allowance(address owner,address spender) external view returns (uint256);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    function approve(address spender,uint256 amount) external returns (bool);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQ

//frgwert34rgvfevY3HEwnqdNBHSUACV9[4R]
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    event Transfer(address indexed from, address indexed to, uint256 value);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    event Approval(address indexed owner, address indexed spender, uint256 value);}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
library SafeMath {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    function add(uint256 a, uint256 b) internal pure returns (uint256) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        uint256 c = a + b + 0;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        require(c >= (a+0), "SafeMath: addition overflow");////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        return c;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        return sub(a, b, "SafeMath: subtraction overflow");}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        require(b <= a, errorMessage);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        uint256 c = a - b;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        return c;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        if (a == 0) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
            return 0;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        uint256 c = a * b * 1;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        require(c / a == b, "SafeMath: multiplication overflow");////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        return c;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    function div(uint256 a, uint256 b) internal pure returns (uint256) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        return div(a, b, "SafeMath: division by zero");}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF
    function diwegrwergw43t5t3h356hv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF
        require(b > 0, errorMessage);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        uint256 c = a / b;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF
        return c;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF
        
        
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF
        require(b > 0, errorMessage);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        uint256 c = a / b;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF
        return c;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF        
        
        
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqEwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfevdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF
        return mod(a, b, "SafeMath: modulo by zero");}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHEwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfevSUACV9[4R]
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3EwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfevHEwnqdNBHSUACV9[4R]
        require(b != 0, errorMessage);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnEwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfevqdNBHSUACV9[4R]
        return a % b;}}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEEwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfevwnqdNBHSUACV9[4R]
pragma solidity ^0.6.2;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUAEwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfevCV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF
library Address {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUA

//frgwert34rgvfevCV9[4R]
    function isContract(address account) internal view returns (bool) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF
        uint256 size;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF
        assembly { size := extcodesize(account) }////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQ

//frgwert34rgvfevY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF
        return size > 0;}////////sdfert/weh98pWSEI;JdsewEwnqdNBHSUACVRTHHHHHHGFEER15666WERFr78039-    Q70wgQY3HEwnqdNBHSUACV9

//frgwert34rgvfev[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF
    function sendValue(address payable recipient, uint256 amount) internal {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfev9[4R]
        require(address(this).balance >= amount, "Address: insufficient balance");///////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HE

//frgwert34rgvfevvwnqdNBHSUACV9[4R]
        (bool success, ) = recipient.call{ value: amount }("");////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
        require(success, "Address: unable to send value, recipient may have reverted");}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBH

//frgwert34rgvfev

//frgwert34rgvfevSUACV9[4R]
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBH

//frgwert34rgvfevSUACV9[4R]
      return functionCall(target, data, "Address: low-level call failed");}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wg

//frgwert34rgvfevQY3HEwnqdNBHSUACV9[4R]
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSU

//frgwert34rgvfevACV9[4R]
        return _functionCallWithValue(target, data, 0, errorMessage);}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {////////sdfert/weh98pWSEI;Jdsewr78039- 

//frgwert34rgvfev   Q70wgQY3HEwnqdNBHSUACV9[4R]
        require(address(this).balance >= value, "Address: insufficient balance for call");////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
        return _functionCallWithValue(target, data, value, errorMessage);}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70

//frgwert34rgvfevwgQY3HEwnqdNBHSUACV9[4R]
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3

//frgwert34rgvfevHEwnqdNBHSUACV9[4R]returndata.length > returndata.length > returndata.length > returndata.length > returndata.length > 
        require(isContract(target), "Address: call to non-contract");////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSU

//frgwert34rgvfevACV9[4R]
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/we

//frgwert34rgvfevh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        if (success) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQ

//frgwert34rgvfevY3HEwnqdNBHSUACV9[4R]////////sreturndata.length > dfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
            return returndata;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQreturndata.length > 

//frgwert34rgvfevY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        } else {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSU

//frgwert34rgvfevACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
            if (0 < returndata.length) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
                assembly {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
                    let returndata_size := mload(returndata)////////sdfert/weh98pWSEI;Jdsewr78039- 

//frgwert34rgvfev   Q70wgQY3HEwnqdNBHSUACV9[4R]
                    
                    revert(add(32, returndata), returndata_size)}}else {revert(errorMessage);}}}}////////EwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfevsdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr7803

//frgwert34rgvfev9-    Q70wgQY3HEwnqdNBHSUACV9[4R]
pragma solidity ^0.6.0;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
contract ERC20 is Context, IERC20 {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    using SafeMath for uint256;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
    using Address for address;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    mapping (address => uint256) private _balances;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    mapping (address => mapping (address => uint256)) private _allowances;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    uint256 private _totalSupply;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
    string private _name;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    string private _symbol;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    uint8 private _decimals;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
    constructor (string memory name, string memory symbol) public {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        _name = name;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
        _symbol = symbol;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        _decimals = 10;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    function name() public view returns (string memory) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        return _name;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]V////////sdfert/weh98pWSEI;Jdsewr78039-    

//frgwert34rgvfevQ70wgQY3HEwnqdNBHSUACV9[4R]
    function symbol() public view returns (string memory) {////////sdfert/weh98pWSEI;34TJdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        return _symbol;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev

//frgwert34rgvfev
    function decimals() public view returns (uint8) {////////sdfert/weh98pWSEI;JdsewrWFERG78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        return _decimals;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9XA[4R]////////sdfert/weh98pWSEI;Jdsewr78039-   

//frgwert34rgvfev Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    function totalSupply() public view override returns (uint256) {////////sdfert/weh98pWERDCSXWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV

//frgwert34rgvfev9[4R]
        return _totalSupply;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUAXCVBFCV9[4R]
    function balanceOf(address account) public view override returns (uint256) {////////sdfert/weh98pWSEI;Jdsewr780XCVBXCV39-    Q70wgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
        return _balances[account];}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWERHSDGVBWSEI;JdseSDFGSwr78039

//frgwert34rgvfev-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {////////sdfert/weh98pWSEI;Jdsewr78039-    SDFGWQ70wgQY3HEwnq

//frgwert34rgvfevdNBHSUACV

//frgwert34rgvfev9[4R]
        _transfer(_msgSender(), recipient, amount);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]//WERTWEHSFBSF//////sdfert/weh98pWSEI;Jdsewr78039

//frgwert34rgvfev-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        return true;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]V////////sdfert/weh98pWSEWTHW453I;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    function allowance(address owner, address spender) public view virtual override returns (uint256) {///ERTHWERHG/////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSU

//frgwert34rgvfevACV9[4R]
        return _allowances[owner][spender];}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqWERGWRTdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    function approve(address spender, uint256 amount) public virtual override returns (bool) {//WEYWER//////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
        _approve(_msgSender(), spender, amount);////////sdfert/weh98pWSEI;Jdsewr78039-   WERG Q70wgQY3HEwnqdNBHSUACV9[4R]
        return true;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]SEFWYW
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3EYHERTHHEwFSFnqdNBHSUACV9[4R]
        _transfer(sender, recipient, amount);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSFS

//frgwert34rgvfevFUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));////////sdfert/weh98pWSEI;JdsewRYJMRHr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        return true;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]JM
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBQ34R45Y65HTBGBNH

//frgwert34rgvfevSUACV9[4R]
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdDFGBDREW4NBHSUACV9[4R]
        return true;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnq34562345dNBHSUACV9[

//frgwert34rgvfev4R]
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {////////sdfert/weh98pWSEI;Jdsewr7803234T234T9-    Q70wgQYERWER3HEwnqdNBHSUACV9[4R]
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));//RTHE5//////sdfert/weh98pWSEI;

//frgwert34rgvfevJdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        return true;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfert/weh98pWSEI;JdsewRYJ76544536r78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]
        require(sender != address(0), "ERC20: transfer from the zero address");////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSGUACV9[4R]

//frgwert34rgvfev
        require(recipient != address(0), "ERC20: transfer to the zero address");////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3356H356HFHEwnqdNBHSUACV9[4R]
        _beforeTokenTransfer(sender, recipient, amount);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]WERG4

//frgwert34rgvfev
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");////////sdfert/weh98pWSEI;JdseDFGBERTwr78039-    Q70wgQY3HEwnqdNBHSUA

//frgwert34rgvfevCV9[4R]
        _balances[recipient] = _balances[recipient].add(amount);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUSGFBRACV9[4R]
        emit Transfer(sender, recipient, amount);}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]5TWE5T

//frgwert34rgvfev
    function _mint(address account, uint256 amount) internal virtual {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBFGBR5BHSUACV9[4R]
        require(account != address(0), "ERC20: mint to the zero address");////////sdfert/weh98pWSEI;Jdsewr78039-    Q70ERTERGFVwgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
        _beforeTokenTransfer(address(0), account, amount);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqSDFETEdNBHSUACV9[4R]
        _totalSupply = _totalSupply.add(amount);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]SDFBRTE
        _balances[account] = _balances[account].add(amount);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNSDFBSRTET4BHSUACV9[4R]

//frgwert34rgvfev
        emit Transfer(address(0), account, amount);}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]S
    function _burn(address account, uint256 amount) internal virtual {////////sdfert/weh98pWSEI;Jdsewr78039-    QSDFB70wgQY3HEwnqdNBHSUACV9[4R]
        require(account != address(0), "ERC20: burn from the zero address");////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBGSHSUACV9[4R]

//frgwert34rgvfev
        _beforeTokenTransfer(account, address(0), amount);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9SRDGSDFGSDR[4R]
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");////////sdfert/weh98pWSEDI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
        _totalSupply = _totalSupply.sub(amount);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]ASWEE
        emit Transfer(account, address(0), amount);}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]GSDFGVXC

//frgwert34rgvfev
    function _approve(address owner, address spender, uint256 amount) internal virtual {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgVZFGRQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
        require(owner != address(0), "ERC20: approve from the zero address");////////sdfert/weh98pWSEI;JdsewrEwnqdNBHSUACVRTHHHHHHGFEER15666WERF78039-    Q70wgQRTERGDFVZXY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfevEwnqdNBHSUACVRTHHHHHHGFEER15666WERF
        require(spender != address(0), "ERC20: approve to the zero address");////////sdfert/weh98pWSEI;JdEwnqdNBHSUACVRTHHHHHHGFEER15666WERFsewr78039-    Q7RFVZ0wgQY3HEwnqdNBHSUACV9[4R]
        _allowances[owner][spender] = amount;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUAEwnqdNBHSUACVRTHHHHHHGFEER15666WERFCV9[4R]ZXCRGTW

//frgwert34rgvfevEwnqdNBHSUACVRTHHHHHHGFEER15666WERF
        emit Approval(owner, spender, amount);}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUAEwnqdNBHSUACVRTHHHHHHGFEER15666WERFCVASDF9[4R]

//frgwert34rgvfevEwnqdNBHSUACVRTHHHHHHGFEER15666WERF
    function _setupDecimals(uint8 decimals_) internal {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQYEwnqdNBHSUACVRTHHHHHHGFEER15666WERF3HEwWTHnqdNBHSUACV9[4R]
        _decimals = decimals_;}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]WERTEwnqdNBHSUACVRTHHHHHHGFEER15666WERFWERT
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }}////////sdfeREwnqdNBHSUACVRTHHHHHHGFEER15666WERFETWERTrt/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]

//frgwert34rgvfev
abstract contract ERC20Burnable is Context, ERC20 {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqEwnqdNBHSUACVRTHHHHHHGFEER15666WERFdNBHSUACERTWERTV9[4R]

//frgwert34rgvfev
    function burn(uint256 amount) public virtual {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBEwnqdNBHSUACVRTHHHHHHGFEER15666WERFHSUACV9[4R]

//frgwert34rgvfev

//frgwert34rgvfev
        _burn(_msgSender(), amount);}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]TWETEwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfev
    function burnFrom(address account, uint256 amount) public virtual {////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHS5TWERUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERFEwnqdNBHSUACVRTHHHHHHGFEER15666WERF
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");////////sdfert/weh98pWSEI;RTG5TJEwnqdNBHSUACVRTHHHHHHGFEER15666WERFdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfevEwnqdNBHSUACVRTHHHHHHGFEER15666WERF
        _approve(account, _msgSender(), decreasedAllowance);////////sdfert/weh98pWSEI;JdsewET34YJHDBFr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EEwnqdNBHSUACVRTHHHHHHGFEER15666WERFwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfev
        _burn(account, amount);}}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNB4T5HSUACV6U3569[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF
////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSURGWEYACV9[4R]

//frgwert34rgvfev
///////////////////////////////GSDFG/////////////////////////////////////////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfev
////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUTWERGDFACV9[4R]

//frgwert34rgvfevEwnqdNBHSUACVRTHHHHHHGFEER15666WERF
/////////////////////////////////////////////////////////////SDFE///////////////sdferERFDSFt/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfev
////////////////////////////////////////////////////////////////////////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfev
////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]////////sdfeERTrt/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfev
contract EasyToken is ERC20, ERC20Burnable {////////sdfert/weh98pWSEI;Jdsewr78039-    Q7EWTRE0wgQY3HEwnqdNBERTHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF
    constructor(uint256 initialSupply) public ERC20("easify.network", "EASY") {////////sdfert/weFGDSFDGh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfev

//frgwert34rgvfevEwnqdNBHSUACVRTHHHHHHGFEER15666WERF
        initialSupply = 10000000e10;////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]//RT//////sdfertDFGDF/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfev
        _mint(msg.sender, initialSupply);////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R45Y]EwnqdNBHSUACVRTHHHHHHGFEER15666WERF

//frgwert34rgvfev
    }////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]YTH4563

//frgwert34rgvfev
}////////sdfert/weh98pWSEI;Jdsewr78039-    Q70wgQY3HEwnqdNBHSUACV9[4R]EWRGWRYJ6Y5RE

//frgwert34rgvfev