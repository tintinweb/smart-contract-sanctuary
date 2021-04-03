pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { CETHInterface, CTokenInterface } from "./interface.sol";

abstract contract CompoundResolver is Events, Helpers {
    /**
     * @dev Deposit ETH/ERC20_Token.
     * @notice Deposit a token to Compound for lending / collaterization.
     * @param token The address of the token to deposit. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param cToken The address of the corresponding cToken.
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
    */
    function depositRaw(
        address token,
        address cToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        require(token != address(0) && cToken != address(0), "invalid token/ctoken address");

        enterMarket(cToken);
        if (token == ethAddr) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            CETHInterface(cToken).mint{value: _amt}();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            tokenContract.approve(cToken, _amt);
            require(CTokenInterface(cToken).mint(_amt) == 0, "deposit-failed");
        }
        setUint(setId, _amt);

        _eventName = "LogDeposit(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, cToken, _amt, getId, setId);
    }

    /**
     * @dev Deposit ETH/ERC20_Token using the Mapping.
     * @notice Deposit a token to Compound for lending / collaterization.
     * @param tokenId The token id of the token to deposit.(For eg: ETH-A)
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
    */
    function deposit(
        string calldata tokenId,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (address token, address cToken) = compMapping.getMapping(tokenId);
        (_eventName, _eventParam) = depositRaw(token, cToken, amt, getId, setId);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @notice Withdraw deposited token from Compound
     * @param token The address of the token to withdraw. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param cToken The address of the corresponding cToken.
     * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens withdrawn.
    */
    function withdrawRaw(
        address token,
        address cToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        
        require(token != address(0) && cToken != address(0), "invalid token/ctoken address");

        CTokenInterface cTokenContract = CTokenInterface(cToken);
        if (_amt == uint(-1)) {
            TokenInterface tokenContract = TokenInterface(token);
            uint initialBal = token == ethAddr ? address(this).balance : tokenContract.balanceOf(address(this));
            require(cTokenContract.redeem(cTokenContract.balanceOf(address(this))) == 0, "full-withdraw-failed");
            uint finalBal = token == ethAddr ? address(this).balance : tokenContract.balanceOf(address(this));
            _amt = finalBal - initialBal;
        } else {
            require(cTokenContract.redeemUnderlying(_amt) == 0, "withdraw-failed");
        }
        setUint(setId, _amt);

        _eventName = "LogWithdraw(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, cToken, _amt, getId, setId);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token using the Mapping.
     * @notice Withdraw deposited token from Compound
     * @param tokenId The token id of the token to withdraw.(For eg: ETH-A)
     * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens withdrawn.
    */
    function withdraw(
        string calldata tokenId,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (address token, address cToken) = compMapping.getMapping(tokenId);
        (_eventName, _eventParam) = withdrawRaw(token, cToken, amt, getId, setId);
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @notice Borrow a token using Compound
     * @param token The address of the token to borrow. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param cToken The address of the corresponding cToken.
     * @param amt The amount of the token to borrow.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens borrowed.
    */
    function borrowRaw(
        address token,
        address cToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        require(token != address(0) && cToken != address(0), "invalid token/ctoken address");

        enterMarket(cToken);
        require(CTokenInterface(cToken).borrow(_amt) == 0, "borrow-failed");
        setUint(setId, _amt);

        _eventName = "LogBorrow(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, cToken, _amt, getId, setId);
    }

     /**
     * @dev Borrow ETH/ERC20_Token using the Mapping.
     * @notice Borrow a token using Compound
     * @param tokenId The token id of the token to borrow.(For eg: DAI-A)
     * @param amt The amount of the token to borrow.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens borrowed.
    */
    function borrow(
        string calldata tokenId,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (address token, address cToken) = compMapping.getMapping(tokenId);
        (_eventName, _eventParam) = borrowRaw(token, cToken, amt, getId, setId);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @notice Payback debt owed.
     * @param token The address of the token to payback. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param cToken The address of the corresponding cToken.
     * @param amt The amount of the token to payback. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens paid back.
    */
    function paybackRaw(
        address token,
        address cToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        require(token != address(0) && cToken != address(0), "invalid token/ctoken address");

        CTokenInterface cTokenContract = CTokenInterface(cToken);
        _amt = _amt == uint(-1) ? cTokenContract.borrowBalanceCurrent(address(this)) : _amt;

        if (token == ethAddr) {
            require(address(this).balance >= _amt, "not-enough-eth");
            CETHInterface(cToken).repayBorrow{value: _amt}();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            require(tokenContract.balanceOf(address(this)) >= _amt, "not-enough-token");
            tokenContract.approve(cToken, _amt);
            require(cTokenContract.repayBorrow(_amt) == 0, "repay-failed.");
        }
        setUint(setId, _amt);

        _eventName = "LogPayback(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, cToken, _amt, getId, setId);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token using the Mapping.
     * @notice Payback debt owed.
     * @param tokenId The token id of the token to payback.(For eg: COMP-A)
     * @param amt The amount of the token to payback. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens paid back.
    */
    function payback(
        string calldata tokenId,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (address token, address cToken) = compMapping.getMapping(tokenId);
        (_eventName, _eventParam) = paybackRaw(token, cToken, amt, getId, setId);
    }

    /**
     * @dev Deposit ETH/ERC20_Token.
     * @notice Same as depositRaw. The only difference is this method stores cToken amount in set ID.
     * @param token The address of the token to deposit. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param cToken The address of the corresponding cToken.
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of cTokens received.
    */
    function depositCTokenRaw(
        address token,
        address cToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        require(token != address(0) && cToken != address(0), "invalid token/ctoken address");

        enterMarket(cToken);

        CTokenInterface ctokenContract = CTokenInterface(cToken);
        uint initialBal = ctokenContract.balanceOf(address(this));

        if (token == ethAddr) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            CETHInterface(cToken).mint{value: _amt}();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            tokenContract.approve(cToken, _amt);
            require(ctokenContract.mint(_amt) == 0, "deposit-ctoken-failed.");
        }

        uint _cAmt;

        {
            uint finalBal = ctokenContract.balanceOf(address(this));
            finalBal - initialBal;
            setUint(setId, _cAmt);
        }

        _eventName = "LogDepositCToken(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, cToken, _amt, _cAmt, getId, setId);
    }

    /**
     * @dev Deposit ETH/ERC20_Token using the Mapping.
     * @notice Same as deposit. The only difference is this method stores cToken amount in set ID.
     * @param tokenId The token id of the token to depositCToken.(For eg: DAI-A)
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of cTokens received.
    */
    function depositCToken(
        string calldata tokenId,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (address token, address cToken) = compMapping.getMapping(tokenId);
        (_eventName, _eventParam) = depositCTokenRaw(token, cToken, amt, getId, setId);
    }

    /**
     * @dev Withdraw CETH/CERC20_Token using cToken Amt.
     * @notice Same as withdrawRaw. The only difference is this method fetch cToken amount in get ID.
     * @param token The address of the token to withdraw. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param cToken The address of the corresponding cToken.
     * @param cTokenAmt The amount of cTokens to withdraw
     * @param getId ID to retrieve cTokenAmt 
     * @param setId ID stores the amount of tokens withdrawn.
    */
    function withdrawCTokenRaw(
        address token,
        address cToken,
        uint cTokenAmt,
        uint getId,
        uint setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _cAmt = getUint(getId, cTokenAmt);
        require(token != address(0) && cToken != address(0), "invalid token/ctoken address");

        CTokenInterface cTokenContract = CTokenInterface(cToken);
        TokenInterface tokenContract = TokenInterface(token);
        _cAmt = _cAmt == uint(-1) ? cTokenContract.balanceOf(address(this)) : _cAmt;

        uint withdrawAmt;
        {
            uint initialBal = token != ethAddr ? tokenContract.balanceOf(address(this)) : address(this).balance;
            require(cTokenContract.redeem(_cAmt) == 0, "redeem-failed");
            uint finalBal = token != ethAddr ? tokenContract.balanceOf(address(this)) : address(this).balance;

            withdrawAmt = sub(finalBal, initialBal);
        }

        setUint(setId, withdrawAmt);

        _eventName = "LogWithdrawCToken(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, cToken, withdrawAmt, _cAmt, getId, setId);
    }

    /**
     * @dev Withdraw CETH/CERC20_Token using cToken Amt & the Mapping.
     * @notice Same as withdraw. The only difference is this method fetch cToken amount in get ID.
     * @param tokenId The token id of the token to withdraw CToken.(For eg: ETH-A)
     * @param cTokenAmt The amount of cTokens to withdraw
     * @param getId ID to retrieve cTokenAmt 
     * @param setId ID stores the amount of tokens withdrawn.
    */
    function withdrawCToken(
        string calldata tokenId,
        uint cTokenAmt,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (address token, address cToken) = compMapping.getMapping(tokenId);
        (_eventName, _eventParam) = withdrawCTokenRaw(token, cToken, cTokenAmt, getId, setId);
    }

    /**
     * @dev Liquidate a position.
     * @notice Liquidate a position.
     * @param borrower Borrower's Address.
     * @param tokenToPay The address of the token to pay for liquidation.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param cTokenPay Corresponding cToken address.
     * @param tokenInReturn The address of the token to return for liquidation.
     * @param cTokenColl Corresponding cToken address.
     * @param amt The token amount to pay for liquidation.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of paid for liquidation.
    */
    function liquidateRaw(
        address borrower,
        address tokenToPay,
        address cTokenPay,
        address tokenInReturn,
        address cTokenColl,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        require(tokenToPay != address(0) && cTokenPay != address(0), "invalid token/ctoken address");
        require(tokenInReturn != address(0) && cTokenColl != address(0), "invalid token/ctoken address");

        CTokenInterface cTokenContract = CTokenInterface(cTokenPay);

        {
            (,, uint shortfal) = troller.getAccountLiquidity(borrower);
            require(shortfal != 0, "account-cannot-be-liquidated");
            _amt = _amt == uint(-1) ? cTokenContract.borrowBalanceCurrent(borrower) : _amt;
        }

        if (tokenToPay == ethAddr) {
            require(address(this).balance >= _amt, "not-enought-eth");
            CETHInterface(cTokenPay).liquidateBorrow{value: _amt}(borrower, cTokenColl);
        } else {
            TokenInterface tokenContract = TokenInterface(tokenToPay);
            require(tokenContract.balanceOf(address(this)) >= _amt, "not-enough-token");
            tokenContract.approve(cTokenPay, _amt);
            require(cTokenContract.liquidateBorrow(borrower, _amt, cTokenColl) == 0, "liquidate-failed");
        }
        
        setUint(setId, _amt);

        _eventName = "LogLiquidate(address,address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            address(this),
            tokenToPay,
            tokenInReturn, 
            _amt,
            getId,
            setId
        );
    }

    /**
     * @dev Liquidate a position using the mapping.
     * @notice Liquidate a position using the mapping.
     * @param borrower Borrower's Address.
     * @param tokenIdToPay token id of the token to pay for liquidation.(For eg: ETH-A)
     * @param tokenIdInReturn token id of the token to return for liquidation.(For eg: USDC-A)
     * @param amt token amount to pay for liquidation.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of paid for liquidation.
    */
    function liquidate(
        address borrower,
        string calldata tokenIdToPay,
        string calldata tokenIdInReturn,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (address tokenToPay, address cTokenToPay) = compMapping.getMapping(tokenIdToPay);
        (address tokenInReturn, address cTokenColl) = compMapping.getMapping(tokenIdInReturn);

        (_eventName, _eventParam) = liquidateRaw(
            borrower,
            tokenToPay,
            cTokenToPay,
            tokenInReturn,
            cTokenColl,
            amt,
            getId,
            setId
        );
    }
}

contract ConnectV2Compound is CompoundResolver {
    string public name = "Compound-v1";
}

pragma solidity ^0.7.0;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
    function gemJoinMapping(bytes32) external view returns (address);
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
    function isAuth(address) external view returns (bool);
}

pragma solidity ^0.7.0;

import { MemoryInterface, InstaMapping } from "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return ethereum address
   */
  address constant internal ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped ETH address
   */
  address constant internal wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F);

  /**
   * @dev Return InstaDApp Mapping Addresses
   */
  InstaMapping constant internal instaMapping = InstaMapping(0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88);

  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : instaMemory.getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) instaMemory.setUint(setId, val);
  }

}

pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { ComptrollerInterface, CompoundMappingInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Compound Comptroller
     */
    ComptrollerInterface internal constant troller = ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    /**
     * @dev Compound Mapping
     */
    CompoundMappingInterface internal constant compMapping = CompoundMappingInterface(0xA8F9D4aA7319C54C04404765117ddBf9448E2082);

    /**
     * @dev enter compound market
     */
    function enterMarket(address cToken) internal {
        address[] memory markets = troller.getAssetsIn(address(this));
        bool isEntered = false;
        for (uint i = 0; i < markets.length; i++) {
            if (markets[i] == cToken) {
                isEntered = true;
            }
        }
        if (!isEntered) {
            address[] memory toEnter = new address[](1);
            toEnter[0] = cToken;
            troller.enterMarkets(toEnter);
        }
    }
}

pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogWithdraw(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogBorrow(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogPayback(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogDepositCToken(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 cTokenAmt,
        uint256 getId, 
        uint256 setId
    );

    event LogWithdrawCToken(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 cTokenAmt,
        uint256 getId,
        uint256 setId
    );
    
    event LogLiquidate(
        address indexed borrower,
        address indexed tokenToPay,
        address indexed tokenInReturn,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );
}

pragma solidity ^0.7.0;

interface CTokenInterface {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint); // For ERC20
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function exchangeRateCurrent() external returns (uint);

    function balanceOf(address owner) external view returns (uint256 balance);
}

interface CETHInterface {
    function mint() external payable;
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;
}

interface ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cTokenAddress) external returns (uint);
    function getAssetsIn(address account) external view returns (address[] memory);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
    function claimComp(address) external;
}

interface CompoundMappingInterface {
    function cTokenMapping(string calldata tokenId) external view returns (address);
    function getMapping(string calldata tokenId) external view returns (address, address);
}

pragma solidity ^0.7.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract DSMath {
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(x, y);
  }

  function sub(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.mul(x, y);
  }

  function div(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.div(x, y);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
  }

  function toInt(uint x) internal pure returns (int y) {
    y = int(x);
    require(y >= 0, "int-overflow");
  }

  function toRad(uint wad) internal pure returns (uint rad) {
    rad = mul(wad, 10 ** 27);
  }

}

pragma solidity ^0.7.0;

import { TokenInterface } from "./interfaces.sol";
import { Stores } from "./stores.sol";
import { DSMath } from "./math.sol";

abstract contract Basic is DSMath, Stores {

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function getTokenBal(TokenInterface token) internal view returns(uint _amt) {
        _amt = address(token) == ethAddr ? address(this).balance : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr) internal view returns(uint buyDec, uint sellDec) {
        buyDec = address(buyAddr) == ethAddr ?  18 : buyAddr.decimals();
        sellDec = address(sellAddr) == ethAddr ?  18 : sellAddr.decimals();
    }

    function encodeEvent(string memory eventName, bytes memory eventParam) internal pure returns (bytes memory) {
        return abi.encode(eventName, eventParam);
    }

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == ethAddr ? TokenInterface(wethAddr) : TokenInterface(buy);
        _sell = sell == ethAddr ? TokenInterface(wethAddr) : TokenInterface(sell);
    }

    function convertEthToWeth(bool isEth, TokenInterface token, uint amount) internal {
        if(isEth) token.deposit{value: amount}();
    }

    function convertWethToEth(bool isEth, TokenInterface token, uint amount) internal {
       if(isEth) {
            token.approve(address(token), amount);
            token.withdraw(amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}