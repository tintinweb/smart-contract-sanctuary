pragma solidity ^0.8.0;
import './IReserve.sol';
import "./IERC20.sol";
import './SafeMath.sol';

contract ReserveA is IReserve {
    using SafeMath for uint256;

    address private owner;
    address public supportedTokenAddress;
    ERC20 private token;
    bool private isTradable;
    uint256 private buyRate; //1 ETH = ? ERC20
    uint256 private sellRate; //? ERC20 = 1 ETH

    constructor(address _supportedTokenAddress, uint256 _buyRate, uint256 _sellRate) {
        owner = msg.sender;
        supportedTokenAddress = _supportedTokenAddress;
        token = ERC20(_supportedTokenAddress);
        isTradable = false;
        buyRate = _buyRate;
        sellRate = _sellRate;
    }

    function setExchangeRates(uint256 _buyRate, uint256 _sellRate) override public onlyOwner
    {
        buyRate = _buyRate;
        sellRate = _sellRate;
    }

    function setReserveTrable() override public {
        isTradable = true;
    }

    function getExchangeRate(bool _isBuy, uint256 _srcAmount) override public view returns(uint256){
        //If it is buy, the srcAmount represent the ETH input
        if(_isBuy){
            uint256 amountToBuy = _srcAmount * buyRate;
            if(token.balanceOf(address(this)) < amountToBuy){
                return 0;
            }
            return amountToBuy;
        }else{
            //If it is sell, srcAmount represent the ERC20    
            uint256 receipt = _srcAmount / sellRate;
            if(address(this).balance < receipt){
                return 0;
            }
            return receipt;
        }
    }

    //Function reserve will delegate transaction to
    //exchange, exchange will directly work with user
    function exchange(bool _isBuy, uint256 _srcAmount) override public payable {
        address trader = msg.sender;
        uint256 exchangeAmount = getExchangeRate(_isBuy, _srcAmount);
        if(exchangeAmount == 0){
            revert('Irrational transaction!!!');
        }

        //when buy ETH is transfer to THIS SC
        //This SC will transfer ERC20 to Exchange SC
        if(_isBuy){
            if(msg.value != _srcAmount){
                revert('Exchange do not send enough ETH!');
            }
            //Transfer ERC20 to Exchange SC
            if(!token.transfer(trader, exchangeAmount)){
                revert('Transfer ERC20 to Exchange failed!');
            }
        }else{
            //When sell, ERC20 will be sent to THIS SC by Exchange SC
            //This SC has to sent back ETH
            if(token.balanceOf(trader) < _srcAmount){
                revert('Buyer do not have enough ERC20!');
            }

            token.transferFrom(trader, address(this), _srcAmount);

            if(address(this).balance < exchangeAmount){
                revert('Reserve do not have enough ETH!');
            }
            
            payable(trader).transfer(exchangeAmount);
        }
    }

    function viewLocalCoins() override public view returns(uint256){
        return token.balanceOf(address(this));
    }

    function viewETH() override public view returns(uint256){
        return address(this).balance;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    receive() external payable {}

    fallback() external payable {}  
}