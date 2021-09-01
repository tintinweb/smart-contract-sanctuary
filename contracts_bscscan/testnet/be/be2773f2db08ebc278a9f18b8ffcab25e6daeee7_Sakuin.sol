// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./IBEP20.sol";
// import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
// import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
// import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Sakuin is IBEP20, Ownable {
    //initial token
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _name;
    string private _symbol;
    address private _devWalletAddress;
    address private  _marketingWalletAddress;

    // fee values using decimal /100
    uint256 public basicFee = 300;
    uint256 public reflectionFee = 400;
    uint256 public liquidityFee = 200;
    //
    
    constructor() {
        _name = "SAKUIN Token";
        _symbol = "SKUT";
        _decimals = 0;
        _totalSupply = 0;
        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[_account];
    }


    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev See {BEP20-burn token}.
     *
     */
    function burn(uint256 _value) external {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= _balances[_who]);
        _balances[_who] = _balances[_who].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
    event Burn(address indexed burner, uint256 value);
    ///////////////////////////////////////////////////
    
    /**
     * @dev can increase total supply
     */
    function mint(uint256 amount) external onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    /////////////////////////////////////////////////////////
    
    /**
     * @dev owner setUp dev address
     */
    function setDevWalletAddress(address _addr) external onlyOwner {
        _devWalletAddress = _addr;
    }
    
    /**
     * @dev owner setUp marketing address
     */
    function setMarketingWalletAddress(address _addr) external onlyOwner {
        _marketingWalletAddress = _addr;
    }
    
    /**
     * @dev owner setUp basicFee
    */
    function setBasicFee(uint256 _basicFee)external onlyOwner{
        basicFee = _basicFee;
    }
    
    /**
     * @dev owner setUp reflectionFee
    */
    function setReflectionFee(uint256 _reflectionFee)external onlyOwner{
        reflectionFee = _reflectionFee;
    }
    
    
}