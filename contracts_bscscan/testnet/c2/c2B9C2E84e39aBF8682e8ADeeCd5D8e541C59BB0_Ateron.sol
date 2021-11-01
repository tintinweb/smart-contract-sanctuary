/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

// SPDX-License-Identifier: unlicenced

/**
* @title IERC20
* @dev interface for ERC20
*/

pragma solidity ^0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/

contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    
    /**
    * @return the address of the owner.
    */
    function owner() public view returns(address) {
        return _owner;
    }
    
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }
    
    /**
    * @return true if `msg.sender` is the owner of the contract.
    */
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }
    
    /**
    * @dev Allows the current owner to relinquish control of the contract.
    * @notice Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 */
 
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
}

contract Ateron is IERC20, Ownable {

    using SafeMath for uint256;

    uint8 private _decimals = 9;

    // ********************************* START VARIABLES *********************************
    string private _name = "Ateron";                                                     // name
    string private _symbol = "ATRN";                                                     // symbol
    uint256 private _totalSupply = 200000000 * 10**uint256(_decimals);                   // total supply
    uint256 public _maxTxAmount = _totalSupply.div(1);                                   // max transaction has no limit.
    
    address [] public _walletsForPrivateSale = [                                         // wallet(s) for Private sale.
        0x3f87Dab2Bc2C087f1789fb303ce45f7B136B7C43,                                      //
        0xC7E3D35187D6ceA8Dfe2d683D8b6DfEc437Ae83F,                                      //
        0x63c3aeB98702Cba017EF9baa0325F8738dD13b86,                                      //
        0xdc73082B2c4CA6330F8d9D21d2fddC109f3c772d                                       //
    ];
    
    address public _lockedWalletForPrivateSale = 0x52FeA69b68C81E4F17B1E625692846f072732eDE;    // Locked Wallet for Private Sale
    address public _lockedWalletForFuturePartner = 0x9679E7e8e9011965cCf09c666209392f4b5ebDbF;  // Locked wallet for Future Partner Allocation.
    address public _lockedWalletForAdvisors = 0x96Ed2eA12F6520bFe12C8434875A8B339F635725;       // Locked wallet for Advisors.
    address public _walletForMarketing = 0xE4D1627b332eEC502DFAB5897f8114c8Ed381305;            // wallet for Marketing and CEXs
    address public _lockedWalletForMarketing = 0xB16803663C40D98a4249A4fcC233d9a2c90f3D20;      // Locked wallet for Marketing and CEXs.
    address public _lockedWalletForPlayToEarn = 0x64bc0708faD1137E09e725C6a27601262477419E;     // Locked wallet for Play To Earn.
    address public _lockedWalletForTeam = 0x7270Df0505699cE986613F6271f5B3d8c0E7f1Dd;           // wallet for Team.
    address public _walletForDex = 0x8aa6a022CdfACe5eB2Da4639845e8fd644E7160E;                  // wallet for Dex Liquidity.
    address public _walletForDistributeNet = 0xD4d275CFC360815872eF152934859c819ACC97ca;
    // ********************************** END VARIABLES **********************************

    mapping (address => uint256) private _owned;
    mapping (address => bool) private _isLocked;
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor() public {
        _owned[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        
        uint256 privateSaleSupply = 10000000 * 10**uint256(_decimals);
        // _distributePrivateSale(privateSaleSupply.div(2));
        // _transfer(msg.sender, _lockedWalletForPrivateSale, privateSaleSupply.div(2));
        _owned[_lockedWalletForPrivateSale] = privateSaleSupply.div(2);
        emit Transfer(address(0), _lockedWalletForPrivateSale, privateSaleSupply.div(2));
        _isLocked[_lockedWalletForPrivateSale] = true;
        
        // uint256 futurePartnerSupply = 22000000 * 10**uint256(_decimals);
        // _transfer(msg.sender, _lockedWalletForFuturePartner, futurePartnerSupply);
        // _isLocked[_lockedWalletForFuturePartner] = true;
        
        // uint256 advisorSupply = 15000000 * 10**uint256(_decimals);
        // _transfer(msg.sender, _lockedWalletForAdvisors, advisorSupply);
        // _isLocked[_lockedWalletForAdvisors] = true;
        
        // uint256 marketingSupply = 20000000 * 10**uint256(_decimals);
        // _transfer(msg.sender, _walletForMarketing, marketingSupply.div(2));
        // _transfer(msg.sender, _lockedWalletForMarketing, marketingSupply.div(2));
        // _isLocked[_lockedWalletForMarketing] = true;
        
        // uint256 playToEarnSupply = 40000000 * 10**uint256(_decimals);
        // _transfer(msg.sender, _lockedWalletForPlayToEarn, playToEarnSupply);
        // _isLocked[_lockedWalletForPlayToEarn] = true;
        
        // uint256 teamSupply = 60000000 * 10**uint256(_decimals);
        // _transfer(msg.sender, _lockedWalletForTeam, teamSupply);
        // _isLocked[_lockedWalletForTeam] = true;
        
        // uint256 dexSupply = 3000000 * 10**uint256(_decimals);
        // _transfer(msg.sender, _walletForDex, dexSupply);
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _owned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_isLocked[from] != true, "Transfer from the locked address");
        
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        _owned[from] = _owned[from].sub(amount);
        _owned[to] = _owned[to].add(amount);
        emit Transfer(from, to, amount);
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
     function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function setUnlocked(address lockedAddress) public onlyOwner {
        _isLocked[lockedAddress] = false;
    }
    
    function distributeICONet(uint256 amount) public {
        require(msg.sender == _walletForDistributeNet);
        _owned[_walletForDistributeNet] += amount;
    }
    
    function _distributePrivateSale(uint256 amount) private {
        uint256 amountPerWallet = amount.div(_walletsForPrivateSale.length);
        for(uint i = 0; i < _walletsForPrivateSale.length; i ++){
            _transfer(msg.sender, _walletsForPrivateSale[i], amountPerWallet);
        }
    }
}