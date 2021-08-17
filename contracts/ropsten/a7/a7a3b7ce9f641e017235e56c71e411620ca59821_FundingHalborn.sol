/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

pragma solidity 0.8.3;

interface ETH_RUNE {
    function giveMeRUNE() external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface iROUTER {
    function deposit(address payable, address, uint, string memory) external payable; 
}

contract FundingHalborn {

    ETH_RUNE rune;
    iROUTER router;

    address vault;

    constructor (){
        rune = ETH_RUNE(0xd601c6A3a36721320573885A8d8420746dA3d7A0);
        router = iROUTER(0xefA28233838f46a80AaaC8c309077a9ba70D123A);
        vault = address(0x3d6FB2051192737f27b629503F6247bfB2A9256e);
    }

    function setVault(address newvault) public {
        vault = newvault;
    }

    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }


    function giveRune(uint256 amount) public payable {

        uint256 times = amount / 1000;

        for (uint i=0; i<times; i++) {
            rune.giveMeRUNE();
        }

        uint256 _safeamount = times * 1000 * 1e18;

        rune.transfer(msg.sender, _safeamount);
        // router.deposit{value:msg.value}(payable(vault), address(rune), _safeamount, append("SWITCH", thoraddress));
    }

    function withdrawAll() public {
        rune.transfer(msg.sender, rune.balanceOf(address(this)));
    }
}