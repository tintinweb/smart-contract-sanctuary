pragma solidity ^0.4.19;

contract AppCoins {
    mapping (address => mapping (address => uint256)) public allowance;
    function balanceOf (address _owner) public constant returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (uint);
}

contract AppCoinsIABInterface {
    function division(uint numerator, uint denominator) public constant returns (uint);
    function buy(uint _amount, string _sku, address _addr_appc, address _dev, address _appstore, address _oem) public constant returns (bool);
}

contract AppCoinsIAB is AppCoinsIABInterface {
    uint public dev_share = 85;
    uint public appstore_share = 10;
    uint public oem_share = 5;

    event Buy(uint _amount, string _sku, address _from, address _dev, address _appstore, address _oem);

    function division(uint numerator, uint denominator) public constant returns (uint) {
        uint _quotient = numerator / denominator;
        return _quotient;
    }

    function buy(uint256 _amount, string _sku, address _addr_appc, address _dev, address _appstore, address _oem) public constant returns (bool) {
        require(_addr_appc != 0x0);
        require(_dev != 0x0);
        require(_appstore != 0x0);
        require(_oem != 0x0);

        AppCoins appc = AppCoins(_addr_appc);
        uint256 aux = appc.allowance(msg.sender, address(this));
        require(aux >= _amount);

        uint[] memory amounts = new uint[](3);
        amounts[0] = division(_amount * dev_share, 100);
        amounts[1] = division(_amount * appstore_share, 100);
        amounts[2] = division(_amount * oem_share, 100);

        appc.transferFrom(msg.sender, _dev, amounts[0]);
        appc.transferFrom(msg.sender, _appstore, amounts[1]);
        appc.transferFrom(msg.sender, _oem, amounts[2]);

        Buy(_amount, _sku, msg.sender, _dev, _appstore, _oem);

        return true;
    }
}