// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "../interface/IWBNB.sol";

// https://forum.openzeppelin.com/t/proxy-not-working-with-wbnb-withdraw/10134
contract BnbHelper {
    IWBNB public WBNB;

    constructor(address _wbnb) {
        WBNB = IWBNB(_wbnb);
    }

    // allowance is required
    function unwrap(uint256 _amount) external {
        bool result = WBNB.transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        require(result, "Transfer failed");

        // unwarp
        WBNB.withdraw(_amount);

        // transfer BNB to caller
        address payable receiver = payable(msg.sender);
        receiver.transfer(_amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IWBNB {
    function deposit() external payable;

    function transfer(address dsc, uint256 value) external returns (bool);

    function transferFrom(
        address src,
        address dsc,
        uint256 value
    ) external returns (bool);

    function withdraw(uint256) external;
}