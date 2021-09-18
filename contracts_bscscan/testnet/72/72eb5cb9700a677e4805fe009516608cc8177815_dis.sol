//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.4;

import "./adamant.sol";

contract dis is Ownable {
    address public addy;

    Adamant inter = Adamant(0x8CCB7d516ccd62312B2D7753B1421ed3862ff80b);

    uint256 fees = 100 * 10**9;

    address MarAdd = 0x43DacA63Af2dF0af230A5497ce319549B1a90ED7;

    function updateFees(uint256 _fee) public onlyOwner {
        fees = _fee;
    }

    function updateMar(address _new) public onlyOwner {
        MarAdd = _new;
    }

    function claim(uint256 _blocks) public {
        inter.transfer(msg.sender, _blocks * (fees / 5));
        inter.transfer(
            0x000000000000000000000000000000000000dEaD,
            _blocks * ((fees * 3) / 5)
        );
        inter.transfer(MarAdd, _blocks * (fees / 5));
    }
}