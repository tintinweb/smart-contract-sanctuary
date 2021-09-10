// SPDX-License-Identifier: MIT
pragma solidity >=0.4.26 <0.8.7;

import "./ERC20AsmFn.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pauseable.sol";


interface ERC20 {
     function balanceOf(address who) external view returns (uint256);
     function transfer(address _to, uint256 _value) external returns (bool success);
     function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
     function approve(address _spender, uint256 _value) external returns (bool success);
}


contract Merchant is Pauseable{
    using SafeMath for uint256;
    using ERC20AsmFn for ERC20;

    address platform = 0x9d3D9d37B86CDCF9A04F99d70bbae2F436ea9442;
    address merchant = 0x2A1D7C9c6D7C90390E5bb2C60829FaeEe98E7Bc1;
    address ETH  = 0x000000000000000000000000000000000000bEEF;
    address USDT = 0xE197623283b59609203362C8203EeE33256b01E7;
    // address USDC = 0x4cac0f6fb97efb8e21d00e6adbe84ba8c18a62a4;
    address DAI  = 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735;

    // Token struct, token config
    struct token{
        uint feeRatio;  // Fee ratio, percent.
        uint decimals;   // decimals number.
    }
    mapping(address => token) public mToken;  


    modifier onlyPlatform() {
        require(msg.sender == platform, "Invoke only by platform.");
        _;
    }

    event MoneyAlloted(uint256 amount, address token);

    constructor() public {
        mToken[ETH]  = token(7, 1000000000000000000);
        mToken[USDT] = token(7, 1000000);
        // mToken[USDC] = token(7, 1000000);
        mToken[DAI]  = token(7, 1000000000000000000);
    }

    function() public payable {}

    // The balance of some token on the contract address.
    function balance(address _token) public view returns (uint256) {
        if (_token == ETH) {
            return address(this).balance;
        } {
            ERC20 erc20token = ERC20(_token);
            return erc20token.balanceOf(this);
        }
    }

    // Allot token to definite address.
    function allot (address _token) public payable whenNotPaused {

        uint256  amount = balance(_token);
        uint256  fee = amount * mToken[_token].feeRatio / 100;
        uint256  available = amount - fee;
        require((available > 0 && fee > 0), "Balance is not enough.");

        if (_token == ETH) {
            platform.transfer(fee);
            merchant.transfer(available);
        } else {
            ERC20 erc20token = ERC20(_token);
            require(erc20token.asmTransfer(platform, fee));
            require(erc20token.asmTransfer(merchant, available));
        }
        
        emit MoneyAlloted((fee + available), _token);
    }

    // Standard kill() function to recover funds
    function kill() public onlyOwner {
        // only allow this action if the account sending the signal is the owner.
        selfdestruct(msg.sender);
        // kills this contract and sends remaining funds back to owner.
    }
}