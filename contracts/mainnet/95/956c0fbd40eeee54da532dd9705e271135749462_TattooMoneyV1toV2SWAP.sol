// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

// TattooMoney.io TattooMoney Token SWAP Contract
//
// USE ONLY OWN WALLET (Metamask, TrustWallet, Trezor, Ledger...)
// DO NOT DO DIRECT SEND OR FROM EXCHANGES OR ANY SERVICES
//
// Use ONLY ETH network, ERC20 TAT2 tokens (Not Binance/Tron/whatever!)
//
// Set approval to contract address before using swap!
//
// DO NOT SEND ANY TOKENS DIRECTLY - THEY WILL BE GONE FOREVER!
//
// Use swap function!

import "./interfaces.sol";

contract TattooMoneyV1toV2SWAP {

    // addresses of tokens
    address public immutable newtat2;
    uint8 public constant newtat2decimals = 18;
    address public immutable oldtat2;
    uint8 public constant oldtat2decimals = 6;

    address public owner;
    address public newOwner;

    string constant ERR_TRANSFER = "Token transfer failed";

    event Swapped(address indexed sender, uint256 indexed amount, uint256 indexed newamount);
    event Tokens(uint256 indexed amount);
    event Burned(uint256 indexed amount);

    /**
    Contract constructor
    @param _owner adddress of contract owner
    @param _oldtat2 adddress of old contract
    @param _newtat2 adddress of new contract
     */

    constructor(
        address _owner,
        address _oldtat2,
        address _newtat2
    ) {
        owner = _owner;
        oldtat2 = _oldtat2;
        newtat2 = _newtat2;

        /**
        mainnet:
        oldTAT2=0x960773318c1aeab5da6605c49266165af56435fa; // Old Token SmartContract
        newTAT2=0xb487d0328b109e302b9d817b6f46Cbd738eA08C2;  // new Token SmartContract
        */
    }

    /**
    Get NEW TAT2, use approve/transferFrom
    @param amount number of old TAT2
    */
    function swap(uint256 amount) external {
        uint8 decimals = newtat2decimals - oldtat2decimals;
        uint256 newamount = amount * (10 ** decimals);
        require(
            INterfaces(oldtat2).transferFrom(msg.sender, address(this), amount),
            ERR_TRANSFER
        );
        require(
            INterfaces(newtat2).transfer(msg.sender, newamount),
            ERR_TRANSFER
        );
        emit Swapped(msg.sender, amount, newamount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only for contract Owner");
        _;
    }

    /// Let's burn OLD tokens
    function burn() external onlyOwner {
      uint256 amt = INterfaces(oldtat2).balanceOf(address(this));
      emit Tokens(amt);
      require(
          INterfaces(oldtat2).transfer(address(0), amt),
          ERR_TRANSFER
      );
      emit Burned(amt);
    }

    /// we can recover any ERC20
    function recoverErc20(address token) external onlyOwner {
        uint256 amt = INterfaces(token).balanceOf(address(this));
        if (amt > 0) {
            INterfacesNoR(token).transfer(owner, amt); // use broken ERC20 to ignore return value
        }
    }

    /// be preapared for everything, ETH recovery
    function recoverEth() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function changeOwner(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() external {
        require(
            msg.sender != address(0) && msg.sender == newOwner,
            "Only NewOwner"
        );
        newOwner = address(0);
        owner = msg.sender;
    }
}

// by Patrick