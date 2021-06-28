pragma solidity >=0.6.2 <0.8.0;


import "./ERC20.sol";


contract TeamToken is ERC20 {

    modifier checkIsAddressValid(address ethAddress)
    {
        require(ethAddress != address(0), "[Validation] invalid address");
        require(ethAddress == address(ethAddress), "[Validation] invalid address");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _supply,
        address _owner,
        address _feeWallet
    ) public checkIsAddressValid(_owner) checkIsAddressValid(_feeWallet) ERC20(_name, _symbol) {
        require(_decimals >=8 && _decimals <= 18, "[Validation] Not valid decimals");
        require(_supply > 0, "[Validation] inital supply should be greater than 0");

        _setupDecimals(_decimals);
        _mint(_owner, _supply * 95/100);
        _mint(_feeWallet, _supply * 5/100);       
    }
}