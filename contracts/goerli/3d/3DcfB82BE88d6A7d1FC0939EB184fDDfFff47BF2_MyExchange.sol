/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

pragma solidity 0.8.7;



interface IExchange {
    function calculatePrice(address _token, uint256 _amount) external returns (uint256);

    function buy(
        address _token,
        uint256 _amount,
        address _addressToSendTokens
    ) external payable;

    function sell(
        address _token,
        uint256 _amount,
        address payable _addressToSendEther
    ) external returns (uint256);
}


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MyExchange is IExchange {
    event Buy(address _token, uint256 _amount, address _addressToSendTokens, uint256 priceInEth);
    event Sell(address _token, uint256 _amount, address _addressToSendTokens, uint256 priceInEth);


    uint256 public priceToBuy;
    uint256 public priceToSell;

    constructor(
        uint256 _priceToBuy,
        uint256 _priceToSell
    ) {
        priceToBuy = _priceToBuy;
        priceToSell = _priceToSell;
    }

    function setPrice(uint256 _priceToBuy, uint256 _priceToSell) external {
        priceToBuy = _priceToBuy;
        priceToSell = _priceToSell;
    }

    function calculatePrice(address _token, uint256 _amount) external override returns (uint256) {
        return _amount * priceToBuy;
    }

    function buy(
        address _token,
        uint256 _amount,
        address _addressToSendTokens
    ) external payable override {
        require(msg.value >= _amount * priceToBuy, "You do not have enough eth");
        IERC20(_token).transfer(_addressToSendTokens, _amount);
        emit Buy(_token, _amount, _addressToSendTokens, _amount * priceToBuy);
    }

    function sell(
        address _token,
        uint256 _amount,
        address payable _addressToSendEther
    ) external override returns (uint256) {
        require(_amount <= IERC20(_token).balanceOf(address(this)), "Does not have enough tokens");
        
        uint256 amountToSend = _amount * priceToSell;
        
        _addressToSendEther.transfer(amountToSend);
        emit Sell(_token, _amount, _addressToSendEther, amountToSend);
        return amountToSend;
    }
}