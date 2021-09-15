/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;


contract WE12M_PRESALE {

    uint256 private constant DECIMALS_WE = 8;
    uint256 private constant DECIMALS_BUSD = 18;
    /// contract starts accepting transfers
    uint256 public  dateStart = 1631624211;
    /// hard time limit
    uint256 public  dateEnd = 1631644211;
    uint256 public  tokensSold;
    uint8 public tokensforadolar = 40;


    /// sale is limited by tokens count
    uint256 public tokensLimit = 2962962960000000;

    // addresses of tokens
    address public wetmp = 0x0E3752fE5183F5CB93E568F8148fAE5D209Edf8B;
    address public busd = 0x2123a5f5D1a07d93Ae12d7a1220eEBA14018c318;
    
    address public owner;
    address public newOwner;

    bool public saleEnded;

    // deposited USD tokens per token address
    mapping(address => uint256) private _deposited;

    /// Tokens bought by user
    mapping(address => uint256) public tokensBoughtOf;

    event AcceptedBUSD(address indexed user, uint256 amount);

    string constant ERR_TRANSFER = "Token transfer failed";
    string constant ERR_SALE_LIMIT = "Token sale limit reached";
    string constant ERR_SOON = "TOO SOON";

    constructor(address _owner) { owner = _owner; }


    function payBUSD(uint256 amount) external {
        require(
            INterfaces(busd).transferFrom(msg.sender, address(this), amount),
            ERR_TRANSFER
        );
        _pay(msg.sender, amount / (10**DECIMALS_BUSD));
        _deposited[busd] += amount;
    }

    receive() external payable {}

    function _pay(address user, uint256 usd) internal notEnded {
        uint256 sold = (usd * tokensforadolar) / (10 ** ( DECIMALS_BUSD - DECIMALS_WE));
        tokensSold += sold;
        require(tokensSold <= tokensLimit, ERR_SALE_LIMIT);
        _sendTokens(user, sold);
        emit AcceptedBUSD(user, usd);
    }
    
    

    function _sendTokens(address user, uint256 amount) internal notEnded {
      require(
          INterfaces(wetmp).transfer(user, amount),
          ERR_TRANSFER
      );
    }

    //
    // modifiers
    //

    modifier notEnded() {
        require(!saleEnded, "Sale ended");
        require(
            block.timestamp > dateStart && block.timestamp < dateEnd,
            "Too soon or too late"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only for contract Owner");
        _;
    }

    /// Take out stables, wBTC  and ETH
    function takeAll() external onlyOwner {
        uint256 amt = INterfaces(busd).balanceOf(address(this));
        if (amt > 0) {
            INterfacesNoR(busd).transfer(owner, amt);
        }
        
        amt = address(this).balance;
        if (amt > 0) {
            payable(owner).transfer(amt);
        }
    }

    function recoverErc20(address token) external onlyOwner {
        uint256 amt = INterfaces(token).balanceOf(address(this));
        if (amt > 0) { INterfacesNoR(token).transfer(owner, amt);}
    }

    function recoverEth() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function EndSale() external onlyOwner {
        saleEnded = true;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender != address(0) && msg.sender == newOwner,"Only NewOwner");
        newOwner = address(0);
        owner = msg.sender;
    }
}

interface INterfaces {
    function balanceOf(address) external returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address,address,uint256) external returns (bool);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// For tokens that do not return true on transfers eg. USDT
interface INterfacesNoR {
    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;
}

// by Patrick