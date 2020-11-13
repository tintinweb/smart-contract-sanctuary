pragma solidity ^0.6.0;

abstract contract OasisInterface {
    function getBuyAmount(address tokenToBuy, address tokenToPay, uint256 amountToPay)
        external
        virtual
        view
        returns (uint256 amountBought);

    function getPayAmount(address tokenToPay, address tokenToBuy, uint256 amountToBuy)
        public virtual
        view
        returns (uint256 amountPaid);

    function sellAllAmount(address pay_gem, uint256 pay_amt, address buy_gem, uint256 min_fill_amount)
        public virtual
        returns (uint256 fill_amt);

    function buyAllAmount(address buy_gem, uint256 buy_amt, address pay_gem, uint256 max_fill_amount)
        public virtual
        returns (uint256 fill_amt);
}
