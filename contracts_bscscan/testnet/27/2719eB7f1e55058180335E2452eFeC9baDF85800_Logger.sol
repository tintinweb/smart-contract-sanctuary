//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Logger {

    using LoggerAddressUtils for address;
    using LoggerBalanceUtils for uint256;

    event LogEvent(
        address indexed contractAddress,
        address indexed caller,
        string logName,
        bytes data
    );

    event Invest(
        address indexed caller,
        address indexed lpAddress,
        uint256 pid,
        address[] _inputs,
        uint256[] _amounts
    );

    constructor() {}

    function emitLog() public {
        address[] memory tokenAddresses = new address[](2);
        tokenAddresses[0] = address(this);
        tokenAddresses[1] = address(this);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 2;

        emit LogEvent(
            address(this), 
            msg.sender, 
            "ActionDeposit", 
            abi.encode(address(this), tokenAddresses, amounts, tokenAddresses, amounts, block.number));
    }

    function emitInvestLog() public {
        LogInvest(
            address(this), 
            address(0x73feaa1eE314F8c655E354234017bE2193C9E24E), 
            9, 
            address(0x9e6619A6a6cc869F384EF95f00322EE19CE12556), 
            uint256(9999999));
    }

    /* Logger.sol */

    function LogInvest(
        address _caller,
        address _lpAddress,
        uint256 _pid,
        address _input,
        uint256 _amount
    ) public {
        emit Invest(_caller, _lpAddress, _pid, _input.toList(), _amount.toList());
    }

    function LogInvestWithInputs(
        address _caller,
        address _lpAddress,
        uint256 _pid,
        address[] memory _inputs,
        uint256[] memory _amounts
    ) public {
        emit Invest(_caller, _lpAddress, _pid, _inputs, _amounts);
    }

}

library LoggerAddressUtils {

    function toList(address _token) internal pure returns (address[] memory){
        address[] memory addresses_ = new address[](1);
        addresses_[0] = _token;
        return addresses_;
    }

}

library LoggerBalanceUtils {

    function toList(uint256 _amount) internal pure returns (uint256[] memory){
        uint256[] memory amounts_ = new uint256[](1);
        amounts_[0] = _amount;
        return amounts_;
    }

}

