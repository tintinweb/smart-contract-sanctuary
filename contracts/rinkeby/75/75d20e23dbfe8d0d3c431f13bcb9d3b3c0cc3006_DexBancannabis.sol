pragma solidity 0.4.24;

import './ERC20.sol';
import "./SafeMath.sol";
import './Ownable.sol';

/**
    Contrato para compra de BCA, Pre-sale 2
 */
contract DexBancannabis is Ownable {
    using SafeMath for uint256;

    ERC20 public token;
    address public vaultWallet;
    uint256 public startSale;
    uint256 public isActive = 1;

    event Bought(uint256 amount);

    constructor(ERC20 _token, address _vaultWallet) public {
        vaultWallet = _vaultWallet;
        token = _token;
        startSale = now; // 3 de Enero
    }

    /**
        Buy BCA
     */
    function buy() payable public {
        // 6 meses 
        if(isActive == 1) {
            uint256 amountTobuy = msg.value;
            uint256 dexBalance = token.balanceOf(address(this));
            require(amountTobuy > 0, "You need to send some ETH");
            require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
            
            uint256 weiAmmount;
            weiAmmount = _getTokenAmount(amountTobuy, _getRate());

            token.transfer(msg.sender, weiAmmount);
            vaultWallet.transfer(msg.value);
            emit Bought(weiAmmount);
        }
        else{
            // si ya paso la fecha de la preventa, devolver el eth
            msg.sender.transfer(msg.value);
            emit Bought(0);
        }
    }

    /**
    * obtener la cantidad de BCA por el ETH enviado
    */
    function _getTokenAmount(uint256 _weiAmount, uint256 rate) internal view returns (uint256)
    {
        return _weiAmount.mul(rate);
    }

    function _getRate() internal view returns (uint256)
    {
        uint256 rate = 2812;
        // 3 primeros meses
        if(now <= (startSale + 90 days)) {
            rate = 3031; // +7% de bca
        }
        else {
            // > 4 mes & < 6 mes
            if(now <= (startSale + 182 days)) {
                rate = 2969; // +5% de bca
            }
        }

        return rate; // precio final
    }

    /**
        Activar o no la venta de BCA
     */
    function setActiveInactive(uint256 _isActive) public onlyOwner {
        isActive = _isActive;
    }

}