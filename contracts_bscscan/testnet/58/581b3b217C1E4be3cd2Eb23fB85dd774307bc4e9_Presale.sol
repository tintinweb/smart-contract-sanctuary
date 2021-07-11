/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

pragma solidity 0.6.12;


abstract contract OwnerRole {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor () public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

abstract contract MinterRole {
    mapping(address => bool) private minters;

    event MinterAdded(address indexed _minter);
    event MinterRemoved(address indexed _minter);

    constructor () public {
        addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Minterable: caller is not the minter");
        _;
    }

    function isMinter(address _minter) external view virtual returns (bool) {
        return minters[_minter];
    }

    function addMinter(address _minter) public virtual {
        minters[_minter] = true;
        emit MinterAdded(_minter);
    }

    function removeMinter(address _minter) public virtual {
        minters[_minter] = false;
        emit MinterRemoved(_minter);
    }
}

abstract contract BEP20 is OwnerRole, MinterRole {
    using SafeMath for uint256;

    uint256 public totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals = 18;

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address _account) public view virtual returns (uint256) {
        return balances[_account];
    }

    function allowance(address _from, address _to) external view virtual returns (uint256) {
        return allowances[_from][_to];
    }

    function mint(address _to, uint256 _amount) external virtual onlyMinter {
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) external virtual {
        _burn(msg.sender, _amount);
    }

    function approve(address _to, uint256 _amount) external virtual returns (bool) {
        require(_amount > 0, "BEP20: amount is greater than zero");

        _approve(msg.sender, _to, _amount);
        return true;
    }

    function transfer(address _to, uint256 _amount) external virtual returns (bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) external virtual returns (bool) {
        require(allowances[_from][msg.sender] >= _amount, "BEP20: transfer amount exceeds allowance");

        _transfer(_from, _to, _amount);
        _approve(_from, msg.sender, allowances[_from][msg.sender].sub(_amount));

        return true;
    }

    function increaseAllowance(address _to, uint256 _amount) external virtual returns (bool) {
        require(_amount > 0, "BEP20: amount is greater than zero");

        uint256 total = allowances[msg.sender][_to].add(_amount);
        _approve(msg.sender, _to, total);
        return true;
    }

    function decreaseAllowance(address _to, uint256 _amount) external virtual returns (bool) {
        require(allowances[msg.sender][_to] >= _amount, "BEP20: decreased allowance below zero");
        require(_amount > 0, "BEP20: amount is greater than zero");

        uint256 total = allowances[msg.sender][_to].sub(_amount);
        _approve(msg.sender, _to, total);
        return true;
    }

    function totalSupplyWithoutDeadBalance() public view returns (uint256) {
        return totalSupply.sub(balanceOf(deadAddress));
    }

    function addMinter(address _minter) public onlyOwner override(MinterRole) {
        super.addMinter(_minter);
    }

    function removeMinter(address _minter) public onlyOwner override(MinterRole) {
        super.removeMinter(_minter);
    }

    function _mint(address _to, uint256 _amount) internal virtual {
        require(_to != address(0), "BEP20: mint to the zero address");
        require(_amount > 0, "BEP20: amount is greater than zero");

        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(address(0), _to, _amount);
    }

    function _burn(address _from, uint256 _amount) internal virtual {
        require(_from != address(0), "BEP20: burn from the zero address");
        require(_amount > 0, "BEP20: amount is greater than zero");
        require(balances[_from] >= _amount, "BEP20: burn amount exceeds balance");

        _transferAmount(_from, deadAddress, _amount);
    }

    function _approve(address _from, address _to, uint256 _amount) internal virtual {
        require(_from != address(0), "BEP20: approve from the zero address");
        require(_to != address(0), "BEP20: approve to the zero address");

        allowances[_from][_to] = _amount;
        emit Approval(_from, _to, _amount);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal virtual {
        require(_from != address(0), "BEP20: transfer from the zero address");
        require(_to != address(0), "BEP20: transfer to the zero address");
        require(balances[_from] >= _amount, "BEP20: transfer amount exceeds balance");
        require(_amount > 0, "BEP20: amount is greater than zero");

        _transferAmount(_from, _to, _amount);
    }

    function _transferAmount(address _from, address _to, uint256 _amount) internal virtual {
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(_from, _to, _amount);
    }

}

// SPDX-License-Identifier: MIT
contract Presale is OwnerRole {
    using SafeMath for uint256;

    event Purchase(address indexed _address, uint256 _bnbAmount, uint256 _tokensAmount);
    event TransferBnb(address indexed _address, uint256 _bnbAmount);
    event Paused();
    event Started();

    uint256 public totalBnb;
    uint256 public totalToken;

    BEP20 public token;
    uint256 public rate;
    address payable public transferAddress;

    bool public paused = false;

    uint256 public minPurchase;
    uint256 public maxPurchasePerWallet = 20 ether;

    mapping(address => uint256) private balances;

    constructor(BEP20 _token, uint256 _rate) public {
        token = _token;
        rate = _rate;
        transferAddress = msg.sender;

        minPurchase = _rate;
    }

    receive() external payable {
        purchase();
    }

    function purchase() public payable {
        require(!paused, "Presale: paused");
        require(minPurchase <= msg.value && balances[msg.sender] + msg.value <= maxPurchasePerWallet, "Presale: purchase amount limit");

        uint256 tokensAmount = calculateTokensAmount(msg.value);

        deliverTokens(msg.sender, tokensAmount);

        totalBnb = totalBnb.add(msg.value);
        totalToken = totalToken.add(tokensAmount);

        balances[msg.sender] = balances[msg.sender].add(msg.value);

        emit Purchase(msg.sender, msg.value, tokensAmount);
    }

    function calculateTokensAmount(uint256 _amount) public view returns (uint256)  {
        return _amount.div(rate.div(10000)).mul(10 ** 18).div(10000);
    }

    function balanceOf(address _address) external view returns (uint256) {
        return balances[_address];
    }

    function bnbBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function transferBnb() external onlyOwner {
        uint256 balance = address(this).balance;

        require(balance > 0, "PRESALE: balance must be greater than zero");

        transferAddress.transfer(balance);

        emit TransferBnb(transferAddress, balance);
    }

    function updateMinPurchase(uint256 _minPurchase) external onlyOwner {
        require(_minPurchase >= rate, "PRESALE: the minimum purchase amount must be no less than the rate");
        require(maxPurchasePerWallet >= _minPurchase, "PRESALE: the minimum purchase amount cannot be more than the maximum amount");

        minPurchase = _minPurchase;
    }

    function updateMaxPurchase(uint256 _maxPurchasePerWallet) external onlyOwner {
        require(_maxPurchasePerWallet >= minPurchase, "PRESALE: the maximum purchase amount cannot be less than the minimum amount");

        maxPurchasePerWallet = _maxPurchasePerWallet;
    }

    function updateRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }

    function updateTransferAddress(address payable _transferAddress) external onlyOwner {
        transferAddress = _transferAddress;
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function start() external onlyOwner {
        paused = false;
        emit Started();
    }


    function deliverTokens(address _to, uint256 _amount) internal {
        token.mint(_to, _amount);
    }

}