// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// Imports
import "./ReentrancyGuard.sol";

// Interfaces
interface IERC20 {
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Presale is ReentrancyGuard {
    address public owner; // Dueño del contrato.
    IERC20 public token; // TRTL Token.
    uint public tokensPerBNB = 750; // Cantidad de tokens que se van a repartir por cada BNB aportado.
    uint public ending; // Tiempo que va finalizar la preventa.
    bool public presaleStarted = false; // Indica si la preventa ha sido iniciada o no.
    address public deadWallet = 0x000000000000000000000000000000000000dEaD; // Wallet de quemado.
    mapping(address => bool) public whitelist; // Whitelist de inversores permitidos en la preventa.
    mapping(address => uint) public invested; // Cantidad de BNBs que ha invertido cada inversor en la preventa.

    // Eventos
    event TokensPurchased(address who, uint256 value);

    constructor(IERC20 _token) {
        owner = msg.sender;
        token = _token;
    }

    // Modificadores
    modifier onlyOwner() {
        require(msg.sender == owner, 'You must be the owner.');
        _;
    }

    // Funciones
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
     * @notice Función que te permite comprar tokens. 
     */
    function invest() public payable nonReentrant {
        require(msg.sender != address(0), "Invalid address.");
        require(whitelist[msg.sender], "You must be on the whitelist.");
        require(presaleStarted, "Presale must have started.");
        require(block.timestamp <= ending, "Presale finished.");
        invested[msg.sender] += msg.value; // Actualiza la inversión del inversor.
        require(invested[msg.sender] <= 5 ether, "Your investment cannot exceed 5 BNB.");

        uint _withdrawableTokens = msg.value * tokensPerBNB; // Tokens que va a recibir el inversor.
        require(_withdrawableTokens <= token.balanceOf(address(this)), "Insufficient TRTL balance in contract.");
        token.transfer(msg.sender, _withdrawableTokens);
    
        emit TokensPurchased(msg.sender, _withdrawableTokens);
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
        
        uint _tokenBalance = token.balanceOf(address(this));
        token.transfer(deadWallet, _tokenBalance);
    }
}