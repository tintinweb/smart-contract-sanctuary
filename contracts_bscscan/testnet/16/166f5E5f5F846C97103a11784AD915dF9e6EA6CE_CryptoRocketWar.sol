// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//TODO Revisar si hace falta crear el pair y si hace falta la funcion de addliquidity

import "./Libraries.sol";

contract CryptoRocketWar{
    string public name = "CryptoRocketWar";
    string public symbol = "CRW";
    uint256 public totalSupply = 5 *1000000  * 1000000000000000000; // 5 millones de tokens
    uint8 public decimals = 18;
    address public teamPinksaleWallet; // Dueño del contrato.
    address public marketingWallet; // Dirección de la billetera de marketing.
    address private firstPresaleContract; // Dirección del contrato de la primera preventa.
    address private secondPresaleContract; // Dirección del contrato de la segunda preventa.
    address private teamVestingContract; // Dirección del contrato de vesting para el equipo.
    IUniswapV2Router02 router; // Router.
    address private pancakePairAddress; // Dirección del par.
    uint public liquidityLockTime = 365 days; // Tiempo que va a estar bloqueada la liquidez.
    uint public liquidityLockCooldown;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(address _teamPinksaleWallet, address _marketingWallet, address _firstPresaleContract) {
        teamPinksaleWallet = _teamPinksaleWallet;
        marketingWallet = _marketingWallet;
        firstPresaleContract = _firstPresaleContract;
        //router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); BSC Main
        router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pancakePairAddress = IPancakeFactory(router.factory()).createPair(address(this), router.WETH());

        uint _firstPresaleTokens = 0.1 * 1000000  * 1000000000000000000;
        // This wallet will divide the tokens   1_to the pre-sale in pinksale
        //                                      2_ 80% of the BNBs for liquidity paired with tokens
        //                                      2_releasing a % of tokens per month for the team
        uint _teamPinksaleWalletTokens = 1.75 *1000000  * 1000000000000000000;
        uint _marketingTokens = 0.15 *1000000  * 1000000000000000000;
        // TODO Game contract
        uint _contractTokens = totalSupply - (_teamPinksaleWalletTokens + _marketingTokens + _firstPresaleTokens); // 3 *1000000  * 1000000000000000000

        balanceOf[firstPresaleContract] = _firstPresaleTokens;
        balanceOf[teamPinksaleWallet] = _teamPinksaleWalletTokens;
        balanceOf[marketingWallet] = _marketingTokens;
        balanceOf[address(this)] = _contractTokens;
    }

    modifier onlyOwner() {
        require(msg.sender == teamPinksaleWallet, 'You must be the owner.');
        _;
    }

    /**
     * @notice Función que permite hacer una transferencia.
     * @param _to Dirección del destinatario.
     * @param _value Cantidad de tokens a transferir.
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * @notice Función que permite ver cuanta cantidad de tokens tiene permiso para gastar una dirección.
     * @param _owner Dirección de la persona que da permiso a gastar sus tokens.
     * @param _spender Dirección a la que se le da permiso para gastar los tokens.
     */
    function allowance(address _owner, address _spender) public view virtual returns (uint256) {
        return _allowances[_owner][_spender];
    }

    /**
     * @notice Función que incrementa el allowance.
     * @param _spender Dirección a la que se le da permiso para gastar tokens.
     * @param _addedValue Cantidad de tokens que das permiso para que gasten.
     */
    function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
        _approve(msg.sender, _spender, _allowances[msg.sender][_spender] + _addedValue);

        return true;
    }

    /**
     * @notice Función que disminuye el allowance.
     * @param _spender Dirección a la que se le quita permiso para gastar tokens.
     * @param _subtractedValue Cantidad de tokens que se van a disminuir de la cantidad permitida para gastar.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][_spender];
        require(currentAllowance >= _subtractedValue, "ERC20: decreased allowance below zero");

        unchecked {
            _approve(msg.sender, _spender, currentAllowance - _subtractedValue);
        }

        return true;
    }

    /**
     * @notice Función que llama a la función interna _approve.
     * @param _spender Dirección de la cuenta a la que le das permiso para gastar tus tokens.
     * @param _value Cantidad de tokens que das permiso para que gasten.
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        _approve(msg.sender, _spender, _value);

        return true;
    }

    /**
     * @notice Función interna que permite aprobar a otra cuenta a gastar tus tokens.
     * @param _owner Dirección de la cuenta que da permiso para gastar sus tokens.
     * @param _spender Dirección de la cuenta a la que le das permiso para gastar tus tokens.
     * @param _amount Cantidad de tokens que das permiso para que gasten.
     */
    function _approve(address _owner, address _spender, uint256 _amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    /**
     * @notice Función que permite hacer una transferencia desde una dirección.
     * @param _from Dirección del emisor.
     * @param _to Dirección del destinatario.
     * @param _value Cantidad de tokens a transferir.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= _allowances[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        _allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    /**
     * @notice Función pública que permite quemar tokens.
     * @param _amount Cantidad de tokens que se van a quemar.
     */
    function burn(uint256 _amount) public virtual {
        _burn(msg.sender, _amount);
    }
    
    function burnContractTokens(uint256 _amount) public virtual onlyOwner {
        _burn(address(this), _amount);
    }

    /**
     * @notice Función interna que permite quemar tokens.
     * @param _account Dirección desde la que se van a quemar los tokens.
     * @param _amount Cantidad de tokens que se van a quemar.
     */
    function _burn(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), 'No puede ser la direccion cero.');
        require(balanceOf[_account] >= _amount, 'La cuenta debe tener los tokens suficientes.');

        balanceOf[_account] -= _amount;
        totalSupply -= _amount;

        emit Transfer(_account, address(0), _amount);
    }
    
    /**
     * @notice Función que permite añadir liquidez.
     * @param _tokenAmount Cantidad de tokens que se van a destinar para la liquidez.
     */
    function addLiquidity(uint _tokenAmount) public payable onlyOwner {
        require(_tokenAmount > 0 || msg.value > 0, "Insufficient tokens or BNBs.");
        /* require(IERC20(pancakePairAddress).totalSupply() == 0); */

        _approve(address(this), address(router), _tokenAmount);

        liquidityLockCooldown = block.timestamp + liquidityLockTime;

        router.addLiquidityETH{value: msg.value}(
            address(this),
            _tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    /**
     * @notice Función que permite retirar la liquidez.
     */
    function removeLiquidity() public onlyOwner {
        require(block.timestamp >= liquidityLockCooldown, "Locked");

        IERC20 liquidityTokens = IERC20(pancakePairAddress);
        uint _amount = liquidityTokens.balanceOf(address(this));
        liquidityTokens.approve(address(router), _amount);

        router.removeLiquidityETH(
            address(this),
            _amount,
            0,
            0,
            teamPinksaleWallet,
            block.timestamp
        );
    }
}