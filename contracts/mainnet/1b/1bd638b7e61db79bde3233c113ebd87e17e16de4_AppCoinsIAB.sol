pragma solidity ^0.4.19;

contract AppCoins {
    mapping (address => mapping (address => uint256)) public allowance;
    function balanceOf (address _owner) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (uint);
}

contract AppCoinsIABInterface {
    function division(uint numerator, uint denominator) public view returns (uint);
    function buy(string _packageName, string _sku, uint256 _amount, address _addr_appc, address _dev, address _appstore, address _oem, bytes2 _countryCode) public view returns (bool);
}

contract AppCoinsIAB is AppCoinsIABInterface {

    uint public dev_share = 85;
    uint public appstore_share = 10;
    uint public oem_share = 5;

    mapping (address => bool) allowedAddresses;
    address owner;

    modifier onlyAllowedAddress(string _funcName) {
        if(!allowedAddresses[msg.sender]){
            emit Error(_funcName, "Operation can only be performed by allowed Addresses");
            return;
        }
        _;
    }

    modifier onlyOwner(string _funcName) {
        if(owner != msg.sender){
            emit Error(_funcName, "Operation can only be performed by contract owner");
            return;
        }
        _;
    }


    event Buy(string packageName, string _sku, uint _amount, address _from, address _dev, address _appstore, address _oem, bytes2 countryCode);
    event Error(string func, string message);
    event OffChainBuy(address _wallet, bytes32 _rootHash);

    function AppCoinsIAB() public {
        owner = msg.sender;
    }

    function addAllowedAddress(address _account) public onlyOwner("addAllowedAddress"){
        allowedAddresses[_account] = true;
    }

    function removeAllowedAddress(address _account) public onlyOwner("removeAllowedAddress") {
        allowedAddresses[_account] = false;
    }

    function informOffChainBuy(address[] _walletList, bytes32[] _rootHashList) public onlyAllowedAddress("informOffChainTransaction") {
        if(_walletList.length != _rootHashList.length){
            emit Error("informOffChainTransaction", "Wallet list and Roothash list must have the same lengths");
            return;
        }
        for(uint i = 0; i < _walletList.length; i++){
            emit OffChainBuy(_walletList[i],_rootHashList[i]);
        }
    }

    function division(uint _numerator, uint _denominator) public view returns (uint) {
        uint quotient = _numerator / _denominator;
        return quotient;
    }


    function buy(string _packageName, string _sku, uint256 _amount, address _addr_appc, address _dev, address _appstore, address _oem, bytes2 _countryCode) public view returns (bool) {
        require(_addr_appc != 0x0);
        require(_dev != 0x0);
        require(_appstore != 0x0);
        require(_oem != 0x0);

        AppCoins appc = AppCoins(_addr_appc);
        uint256 aux = appc.allowance(msg.sender, address(this));
        if(aux < _amount){
            emit Error("buy","Not enough allowance");
            return false;
        }

        uint[] memory amounts = new uint[](3);
        amounts[0] = division(_amount * dev_share, 100);
        amounts[1] = division(_amount * appstore_share, 100);
        amounts[2] = division(_amount * oem_share, 100);

        appc.transferFrom(msg.sender, _dev, amounts[0]);
        appc.transferFrom(msg.sender, _appstore, amounts[1]);
        appc.transferFrom(msg.sender, _oem, amounts[2]);

        emit Buy(_packageName, _sku, _amount, msg.sender, _dev, _appstore, _oem, _countryCode);

        return true;
    }
}