/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract SwapCoin is Ownable {
    using SafeMath for *;
    uint public immutable startNumber;

    bool public isActivated = true;
    bool public isAllowETH = false;

    uint public depositCount = 0;
    uint public withdrawCount = 0;

    uint public minCoinAmount = 1;
    uint public coinFeeAmount = 0;    

    struct TokenInfo{
        address url; //contract-address
        string symbol; //symbol
        uint8 decimal;
        bool listed;
        bool isAllowed;
        uint minAmount;
        uint feeAmount;
    }
    mapping(address => TokenInfo) public allowedToken;
    address[] public listedTokens;

    constructor() public{
        startNumber = block.number;
    }

    modifier onlyActivated {
        require(isActivated, 'unactivated');
        _;
    }

    function getAllowTokenCount() public view returns (uint){
        return listedTokens.length;
    }

    function setActivate(bool _actived) public onlyOwner {
        require(isActivated != _actived, 'ERR_1');
        isActivated = _actived;
    }

    function getCoinInfo() public view returns(bool allow, uint min, uint fee){
        allow = isAllowETH;
        min = minCoinAmount;
        fee = coinFeeAmount;
    }

    function getTokenInfo() public view returns(TokenInfo[] memory infos){
        uint size;
        for(uint i; i<listedTokens.length ; i++){
            if (allowedToken[listedTokens[i]].isAllowed) {
                size++;
            }
        }//for

        infos = new TokenInfo[](size);

        uint index;
        for(uint i; i<listedTokens.length ; i++){
            if (allowedToken[listedTokens[i]].isAllowed) {
                infos[index] = allowedToken[listedTokens[i]];
                index++;
            }
        }//for

    }


    function setAllowETH(bool f) public onlyOwner{
        require(isAllowETH != f , 'ERR_1');
        isAllowETH = f;
    }
    function setAllowToken(address token, bool f , uint _min, uint _fee) public onlyOwner{
        require(IERC20(token).decimals() > 0 , 'IS_ERC20_?');

        if (allowedToken[token].listed == false){
            allowedToken[token].listed = true;
            listedTokens.push(token);
        }        
        allowedToken[token].isAllowed = f;
        if (f){
            allowedToken[token].url = token;
            allowedToken[token].symbol = IERC20(token).symbol();
            allowedToken[token].decimal = IERC20(token).decimals();
            allowedToken[token].minAmount = _min;
            allowedToken[token].feeAmount = _fee;
        }
    }

    function setMinCoinAmount(uint amount) public onlyOwner{
        minCoinAmount = amount;
    }
    function setFeeCoinAmount(uint amount) public onlyOwner{
        coinFeeAmount = amount;
    }

    //event
    event DepositCoin(address from, uint amount, uint fee);
    event DepositToken(address token , address from, uint amount, uint fee);
    event WithdrawCoinOwner(address from, uint amount);
    event WithdrawTokenOwner(address token, address from, uint amount);

    receive() payable external{
        assert(false);
    }

    function depositCoin(uint _fee) public payable onlyActivated {   //ETH
        assert(isAllowETH);
        assert(msg.value >= minCoinAmount);
        assert(_fee == coinFeeAmount);

        depositCount = depositCount.add(1);

        emit DepositCoin(msg.sender , msg.value , _fee);
    }

    function depositToken(address token, uint _amount, uint _fee) public onlyActivated { //PTX
        require(allowedToken[token].isAllowed , 'UNLISTED_TOKEN');
        require(_amount >= allowedToken[token].minAmount, 'MIN_AMOUNT');
        require(_amount > allowedToken[token].feeAmount, 'FEE_AMOUNT');
        require(_fee == allowedToken[token].feeAmount, 'FEE_VALID');

        if(!IERC20(token).transferFrom(msg.sender, address(this), _amount)) {
            revert();
        }

        depositCount = depositCount.add(1);

        emit DepositToken(token, msg.sender, _amount, _fee);
    }

    function balanceOfCoin() public view returns (uint){
        return address(this).balance;
    }
    function balanceOfToken(address token) public view returns (uint){
        return IERC20(token).balanceOf(address(this));
    }

    function withdrawCoinOwner(address to, uint _amount) public onlyOwner{
        require(address(this).balance >= _amount, 'ERR_1');
        TransferHelper.safeTransferETH(to, _amount);

        withdrawCount = withdrawCount.add(1);

        emit WithdrawCoinOwner(to, _amount);
    }
    function withdrawTokenOwner(address token, address to, uint _amount) public onlyOwner{
        uint amount = IERC20(token).balanceOf(address(this));
        require(amount >= _amount , 'ERR_1');
        TransferHelper.safeTransfer(token, to, _amount);

        withdrawCount = withdrawCount.add(1);

        emit WithdrawTokenOwner(token, to, _amount);
    }

    

    
}


library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'math_add_over');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'math_sub_over');
    }
    function sub128(uint x , uint y) internal pure returns (uint128 z){
        return uint128(sub(x , y));
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'math_mul_over');
    }

    function div(uint x, uint y) internal pure returns (uint z){
        require(y > 0, 'math_div_0');
        z = x / y;
    }

    function mod(uint x, uint y) internal pure returns (uint z){
        require(y != 0, 'math_mod_0');
        z = x % y;
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}