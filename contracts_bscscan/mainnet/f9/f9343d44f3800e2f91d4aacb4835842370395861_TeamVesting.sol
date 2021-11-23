// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// Imports
import "./Libraries.sol";

contract TeamVesting is ReentrancyGuard {
    IERC20 public token;
    address public teamWallet; // Wallet del equipo.
    uint public cooldownTime = 30 days; // Tiempo de cooldown que va a tener el claim.
    uint public claimReady; // Guarda el tiempo en el que el usuario podrá hacer el próximo claim.
    bool private tokenAvailable = false;
    uint public initialContractBalance; // Initial contract balance.
    bool private initialized; // Checks if the variable initializedContractBalance has been defined.

    constructor(address _teamWallet) {
        teamWallet = _teamWallet;
    }

    modifier onlyOwner() {
        require(msg.sender == teamWallet, 'You must be the owner.');
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
     * @notice Función que permite hacer claim de los tokens que se pueden claimear (8,33% cada mes).
     */
    function claimTokens() public onlyOwner nonReentrant {
        require(claimReady <= block.timestamp, "You can't claim now.");
        require(token.balanceOf(address(this)) > 0, "Insufficient Balance.");

        if(!initialized) {
            initialContractBalance = token.balanceOf(address(this));
            initialized = true;
        }

        uint _withdrawableBalance = mulScale(initialContractBalance, 833, 10000); // 833 basis points = 8,33%.

        if(token.balanceOf(address(this)) <= _withdrawableBalance) {
            token.transfer(teamWallet, token.balanceOf(address(this)));
        } else {
            claimReady = block.timestamp + cooldownTime;

            token.transfer(teamWallet, _withdrawableBalance); 
        }
    }
}