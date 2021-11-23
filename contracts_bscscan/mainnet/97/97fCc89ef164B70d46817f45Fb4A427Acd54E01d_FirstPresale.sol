// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// Imports
import "./Libraries.sol";

contract FirstPresale is ReentrancyGuard {
    address public owner; // Dueño del contrato.
    IERC20 public token; // MYM Token.
    bool private tokenAvailable = false;
    uint public tokensPerBNB = 8000; // Cantidad de MYMs que se van a repartir por cada BNB aportado.
    uint public ending; // Tiempo que va finalizar la preventa.
    bool public presaleStarted = false; // Indica si la preventa ha sido iniciada o no.
    address public deadWallet = 0x000000000000000000000000000000000000dEaD; // Wallet de quemado.
    uint public cooldownTime = 30 days;
    uint public tokensSold;

    mapping(address => bool) public whitelist; // Whitelist de inversores permitidos en la preventa.
    mapping(address => uint) public invested; // Cantidad de BNBs que ha invertido cada inversor en la preventa.
    mapping(address => uint) public investorBalance;
    mapping(address => uint) public withdrawableBalance;
    mapping(address => uint) public claimReady;

    constructor(address _teamWallet) {
        owner = _teamWallet;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'You must be the owner.');
        _;
    }

    /**
     * @notice Función que actualiza el token en el contrato (Solo se puede hacer 1 vez).
     * @param _token Dirección del contrato del token.
     */
    function setToken(IERC20 _token) public onlyOwner {
        require(!tokenAvailable, "Token is already inserted.");
        token = _token;
        tokenAvailable = true;
    }

    /**
     * @notice Función que permite añadir inversores a la whitelist.
     * @param _investor Direcciones de los inversores que entran en la whitelist.
     */
    function addToWhitelist(address[] memory _investor) public onlyOwner {
        for (uint _i = 0; _i < _investor.length; _i++) {
            require(_investor[_i] != address(0), 'Invalid address.');
            address _investorAddress = _investor[_i];
            whitelist[_investorAddress] = true;
        }
    }

    /**
     * @notice Función que inicia la Preventa (Solo se puede iniciar una vez).
     * @param _presaleTime Tiempo que va a durar la preventa.
     */
    function startPresale(uint _presaleTime) public onlyOwner {
        require(!presaleStarted, "Presale already started.");

        ending = block.timestamp + _presaleTime;
        presaleStarted = true;
    }

    /**
     * @notice Función que te permite comprar MYMs. 
     */
    function invest() public payable nonReentrant {
        require(whitelist[msg.sender], "You must be on the whitelist.");
        require(presaleStarted, "Presale must have started.");
        require(block.timestamp <= ending, "Presale finished.");
        invested[msg.sender] += msg.value; // Actualiza la inversión del inversor.
        require(invested[msg.sender] >= 0.10 ether, "Your investment should be more than 0.10 BNB.");
        require(invested[msg.sender] <= 10 ether, "Your investment cannot exceed 10 BNB.");

        uint _investorTokens = msg.value * tokensPerBNB; // Tokens que va a recibir el inversor.
        investorBalance[msg.sender] += _investorTokens;
        withdrawableBalance[msg.sender] += _investorTokens;
        tokensSold += _investorTokens;
    }

    /**
     * @notice Calcula el % de un número.
     * @param x Número.
     * @param y % del número.
     * @param scale División.
     */
    function mulScale (uint x, uint y, uint128 scale) internal pure returns (uint) {
        uint a = x / scale;
        uint b = x % scale;
        uint c = y / scale;
        uint d = y % scale;

        return a * c * scale + a * d + b * c + b * d / scale;
    }

    /**
     * @notice Función que permite a los inversores hacer claim de sus tokens disponibles.
     */
    function claimTokens() public nonReentrant {
        require(whitelist[msg.sender], "You must be on the whitelist.");
        require(block.timestamp > ending, "Presale must have finished.");
        require(claimReady[msg.sender] <= block.timestamp, "You can't claim now.");
        uint _contractBalance = token.balanceOf(address(this));
        require(_contractBalance > 0, "Insufficient contract balance.");
        require(investorBalance[msg.sender] > 0, "Insufficient investor balance.");

        uint _withdrawableTokensBalance = mulScale(investorBalance[msg.sender], 2500, 10000); // 2500 basis points = 25%.

        // Si tu balance es menor a la cantidad que puedes retirar directamente te transfiere todo tu saldo.
        if(withdrawableBalance[msg.sender] <= _withdrawableTokensBalance) {
            token.transfer(msg.sender, withdrawableBalance[msg.sender]);

            investorBalance[msg.sender] = 0;
            withdrawableBalance[msg.sender] = 0;
        } else {
            claimReady[msg.sender] = block.timestamp + cooldownTime; // Actualiza cuando será el próximo claim.

            withdrawableBalance[msg.sender] -= _withdrawableTokensBalance; // Actualiza el balance del inversor.

            token.transfer(msg.sender, _withdrawableTokensBalance); // Transfiere los tokens.
        }
    }

    /**
     * @notice Función que permite retirar los BNBs del contrato a la dirección del owner.
     */
    function withdrawBnbs() public onlyOwner {
        uint _bnbBalance = address(this).balance;
        payable(owner).transfer(_bnbBalance);
    }

    /**
     * @notice Función que quema los tokens que sobran en la preventa.
     */
    function burnTokens() public onlyOwner {
        require(block.timestamp > ending, "Presale must have finished.");
        
        uint _contractBalance = token.balanceOf(address(this));
        uint _tokenBalance = _contractBalance - tokensSold;
        token.transfer(deadWallet, _tokenBalance);
    }
}