/**
 *Submitted for verification at Etherscan.io on 2020-04-19
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


interface CTokenInterface {
    function mint(uint mintAmount) external returns (uint); // For ERC20
    function redeem(uint redeemTokens) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint); // For ERC20

    function borrowBalanceCurrent(address) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function borrow(uint) external returns (uint);
    function underlying() external view returns (address);
    function borrowBalanceStored(address) external view returns (uint);
}

interface CETHInterface {
    function mint() external payable; // For ETH
    function repayBorrow() external payable; // For ETH
}

interface ComptrollerInterface {
    function getAssetsIn(address account) external view returns (address[] memory);
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cTokenAddress) external returns (uint);
}

interface AccountInterface {	
    function version() external view returns (uint);	
}

interface ListInterface {
    function accountID(address) external view returns (uint64);
}

interface IndexInterface {
    function master() external view returns (address);
    function list() external view returns (address);
    function isClone(uint, address) external view returns (bool);
}

interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function decimals() external returns (uint);
}

contract DSMath {
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }
}


contract Helpers is DSMath {

    address constant public instaIndex = 0x2971AdFa57b20E5a416aE5a708A8655A9c74f723;
    address constant public comptrollerAddr = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    address constant public ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant public cEth = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    mapping (address => bool) public isTknAllowed;
    mapping (address => address) public tknToCTkn;

    /**
     * FOR SECURITY PURPOSE
     * only Smart DEFI Account can access the liquidity pool contract
     */
    modifier isDSA {
        IndexInterface indexContract = IndexInterface(instaIndex);
        uint64 id = ListInterface(indexContract.list()).accountID(msg.sender);
        require(id != 0, "not-dsa-id");
        require(indexContract.isClone(AccountInterface(msg.sender).version(), msg.sender), "not-dsa-clone");
        _;
    }

    function tokenBal(address token) internal view returns (uint _bal) {
        _bal = token == ethAddr ? address(this).balance : TokenInterface(token).balanceOf(address(this));
    }

    function _transfer(address token, uint _amt) internal {
         token == ethAddr ?
             msg.sender.transfer(_amt) :
            require(TokenInterface(token).transfer(msg.sender, _amt), "token-transfer-failed");
    }
}


contract CompoundResolver is Helpers {

    function borrowAndSend(address[] memory tokens, uint[] memory tknAmt) internal {
        if (tokens.length > 0) {
            for (uint i = 0; i < tokens.length; i++) {
                address token = tokens[i];
                address cToken = tknToCTkn[token];
                if (cToken != address(0) && tknAmt[i] > 0) {
                    require(CTokenInterface(cToken).borrow(tknAmt[i]) == 0, "borrow-failed");
                    _transfer(token, tknAmt[i]);
                }
            }
        }
    }

    function payback(address[] memory tokens) internal {
        if (tokens.length > 0) {
            for (uint i = 0; i < tokens.length; i++) {
                address token = tokens[i];
                address cToken = tknToCTkn[token];
                if (cToken != address(0)) {
                    CTokenInterface ctknContract = CTokenInterface(cToken);
                    token != ethAddr ?
                        require(ctknContract.repayBorrow(uint(-1)) == 0, "payback-failed") :
                        CETHInterface(cToken).repayBorrow.value(ctknContract.borrowBalanceCurrent(address(this)))();
                }
            }
        }
    }
}

contract AccessLiquidity is CompoundResolver {
    event LogPoolBorrow(address indexed user, address[] tknAddr, uint[] amt);
    event LogPoolPayback(address indexed user, address[] tknAddr);

    /**
     * @dev borrow tokens and use them on DSA.
     * @param tokens Array of tokens.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amounts Array of tokens amount.
    */
    function accessLiquidity(address[] calldata tokens, uint[] calldata amounts) external isDSA {
        require(tokens.length == amounts.length, "length-not-equal");
        borrowAndSend(tokens, amounts);
        emit LogPoolBorrow(
            msg.sender,
            tokens,
            amounts
        );
    }
   
    /**
     * @dev Payback borrowed tokens.
     * @param tokens Array of tokens.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
    */
    function returnLiquidity(address[] calldata tokens) external payable isDSA {
        payback(tokens);
        emit LogPoolPayback(msg.sender, tokens);
    }
    
    /**
     * @dev Check if no tokens are borrowed.
    */
    function isOk() public view returns(bool ok) {
        ok = true;
        address[] memory markets = ComptrollerInterface(comptrollerAddr).getAssetsIn(address(this));
        for (uint i = 0; i < markets.length; i++) {
            uint tknBorrowed = CTokenInterface(markets[i]).borrowBalanceStored(address(this));
            if(tknBorrowed > 0){
                ok = false;
                break;
            }
        }
    }
}


contract ProvideLiquidity is  AccessLiquidity {
    event LogDeposit(address indexed user, address indexed token, uint amount, uint cAmount);
    event LogWithdraw(address indexed user, address indexed token, uint amount, uint cAmount);

    mapping (address => mapping (address => uint)) public liquidityBalance;

    /**
     * @dev Deposit Liquidity.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
    */
    function deposit(address token, uint amt) external payable returns (uint _amt) {
        require(isTknAllowed[token], "token-not-listed");
        require(amt > 0 || msg.value > 0, "amt-not-valid");

        if (msg.value > 0) require(token == ethAddr, "not-eth-addr");

        address cErc20 = tknToCTkn[token];
        uint initalBal = tokenBal(cErc20);
        if (token == ethAddr) {
            _amt = msg.value;
            CETHInterface(cErc20).mint.value(_amt)();
        } else {
            _amt = amt == (uint(-1)) ? TokenInterface(token).balanceOf(msg.sender) : amt;
            require(TokenInterface(token).transferFrom(msg.sender, address(this), _amt), "allowance/balance?");
            require(CTokenInterface(cErc20).mint(_amt) == 0, "mint-failed");
        }
        uint finalBal = tokenBal(cErc20);
        uint ctokenAmt = sub(finalBal, initalBal);

        liquidityBalance[token][msg.sender] += ctokenAmt;

        emit LogDeposit(msg.sender, token, _amt, ctokenAmt);
    }

    
    /**
     * @dev Withdraw Liquidity.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
    */
    function withdraw(address token, uint amt) external returns (uint _amt) {
        uint _userLiq = liquidityBalance[token][msg.sender];
        require(_userLiq > 0, "nothing-to-withdraw");

        uint _cAmt;

        address ctoken = tknToCTkn[token];
        if (amt == uint(-1)) {
            uint initknBal = tokenBal(token);
            require(CTokenInterface(ctoken).redeem(_userLiq) == 0, "redeem-failed");
            uint finTknBal = tokenBal(token);
            _cAmt = _userLiq;
            delete liquidityBalance[token][msg.sender];
            _amt = sub(finTknBal, initknBal);
        } else {
            uint iniCtknBal = tokenBal(ctoken);
            require(CTokenInterface(ctoken).redeemUnderlying(amt) == 0, "redeemUnderlying-failed");
            uint finCtknBal = tokenBal(ctoken);
            _cAmt = sub(iniCtknBal, finCtknBal);
            require(_cAmt <= _userLiq, "not-enough-to-withdraw");
            liquidityBalance[token][msg.sender] -= _cAmt;
            _amt = amt;
        }
        
        _transfer(token, _amt);
       
        emit LogWithdraw(msg.sender, token, _amt, _cAmt);
    }

}


contract Controllers is ProvideLiquidity {
    event LogEnterMarket(address[] token, address[] ctoken);
    event LogExitMarket(address indexed token, address indexed ctoken);

    modifier isMaster {
        require(msg.sender == IndexInterface(instaIndex).master(), "not-master");
        _;
    }

    function _enterMarket(address[] memory cTknAddrs) internal {
        ComptrollerInterface(comptrollerAddr).enterMarkets(cTknAddrs);
        address[] memory tknAddrs = new address[](cTknAddrs.length);
        for (uint i = 0; i < cTknAddrs.length; i++) {
            if (cTknAddrs[i] != cEth) {
                tknAddrs[i] = CTokenInterface(cTknAddrs[i]).underlying();
                TokenInterface(tknAddrs[i]).approve(cTknAddrs[i], uint(-1));
            } else {
                tknAddrs[i] = ethAddr;
            }
            tknToCTkn[tknAddrs[i]] = cTknAddrs[i];
            isTknAllowed[tknAddrs[i]] = true;
        }
        emit LogEnterMarket(tknAddrs, cTknAddrs);
    }

    /**
     * @dev Enter compound market to enable borrowing.
     * @param cTknAddrs Array Ctoken addresses.
    */
    function enterMarket(address[] calldata cTknAddrs) external isMaster {
        _enterMarket(cTknAddrs);
    }

    /**
     * @dev Exit compound market to disable borrowing.
     * @param cTkn Ctoken address.
    */
    function exitMarket(address cTkn) external isMaster {
        ComptrollerInterface(comptrollerAddr).exitMarket(cTkn);
        address tkn;
        if (cTkn != cEth) {
            tkn = CTokenInterface(cTkn).underlying();
            TokenInterface(tkn).approve(cTkn, 0);
        } else {
            tkn = ethAddr;
        }
        isTknAllowed[tkn] = false;
        emit LogExitMarket(tkn, cTkn);
    }

}


contract InstaPool is Controllers {

    constructor(address[] memory cTknAddrs) public {
        _enterMarket(cTknAddrs);
    }

    receive() external payable {}
}