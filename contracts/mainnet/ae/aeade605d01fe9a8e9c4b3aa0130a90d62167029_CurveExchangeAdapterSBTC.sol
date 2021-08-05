/**
 *Submitted for verification at Etherscan.io on 2020-07-01
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-18
*/

/**
 *Submitted for verification at Etherscan.io on 2020-01-23
*/

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a); // dev: overflow
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a); // dev: underflow
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b); // dev: overflow
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0); // dev: divide by zero
        c = a / b;
    }
}

contract BasicMetaTransaction {

    using SafeMath for uint256;

    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);
    mapping(address => uint256) nonces;
    
    function getChainID() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Main function to be called when user wants to execute meta transaction.
     * The actual function to be called should be passed as param with name functionSignature
     * Here the basic signature recovery is being used. Signature is expected to be generated using
     * personal_sign method.
     * @param userAddress Address of user trying to do meta transaction
     * @param functionSignature Signature of the actual function to be called via meta transaction
     * @param message Message to be signed by the user
     * @param length Length of complete message that was signed
     * @param sigR R part of the signature
     * @param sigS S part of the signature
     * @param sigV V part of the signature
     */
    function executeMetaTransaction(address userAddress,
        bytes memory functionSignature, string memory message, string memory length,
        bytes32 sigR, bytes32 sigS, uint8 sigV) public payable returns(bytes memory) {

        require(verify(userAddress, message, length, nonces[userAddress], getChainID(), sigR, sigS, sigV), "Signer and signature do not match");
        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));

        require(success, "Function call not successfull");
        nonces[userAddress] = nonces[userAddress].add(1);
        emit MetaTransactionExecuted(userAddress, msg.sender, functionSignature);
        return returnData;
    }

    function getNonce(address user) public view returns(uint256 nonce) {
        nonce = nonces[user];
    }



    function verify(address owner, string memory message, string memory length, uint256 nonce, uint256 chainID,
        bytes32 sigR, bytes32 sigS, uint8 sigV) public pure returns (bool) {

        string memory nonceStr = uint2str(nonce);
        string memory chainIDStr = uint2str(chainID);
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", length, message, nonceStr, chainIDStr));
		return (owner == ecrecover(hash, sigV, sigR, sigS));
    }

    /**
     * Internal utility function used to convert an int to string.
     * @param _i integer to be converted into a string
     */
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        uint256 temp = _i;
        while (temp != 0) {
            bstr[k--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(bstr);
    }

    function msgSender() internal view returns(address sender) {
        if(msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }

    // To recieve ether in contract
    receive() external payable { }
    fallback() external payable { }
}

// File: browser/dex-adapter-simple.sol

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

interface IGateway {
    function mint(bytes32 _pHash, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external returns (uint256);
    function burn(bytes calldata _to, uint256 _amount) external returns (uint256);
}

interface IGatewayRegistry {
    function getGatewayBySymbol(string calldata _tokenSymbol) external view returns (IGateway);
    function getGatewayByToken(address  _tokenAddress) external view returns (IGateway);
    function getTokenBySymbol(string calldata _tokenSymbol) external view returns (IERC20);
}

interface ICurveExchange {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

    function get_dy(int128, int128 j, uint256 dx) external view returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool deposit) external returns (uint256 amount);

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity(
        uint256 _amount,
        uint256[3] calldata min_amounts
    ) external;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity_one_coin(uint256 _token_amounts, int128 i, uint256 min_amount) external;
}

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract CurveExchangeAdapterSBTC is BasicMetaTransaction {
    using SafeMath for uint256;

    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 *
                           msg.data.length;
        if(chi.balanceOf(address(this)) > 0) {
            chi.freeFromUpTo(address(this), (gasSpent + 14154) / 41947);
        }
        else {
            chi.freeFromUpTo(msgSender(), (gasSpent + 14154) / 41947);
        }
    }

    uint256 constant N_COINS = 3;
    
    //first coin always is renBTC
    IERC20[N_COINS] coins;
    uint256[N_COINS] precisions_normalized = [1,1,1e10];

    IERC20 curveToken;

    ICurveExchange public exchange;  
    IGatewayRegistry public registry;

    event SwapReceived(uint256 mintedAmount, uint256 erc20BTCAmount, int128 j);
    event DepositMintedCurve(uint256 mintedAmount, uint256 curveAmount, uint256[N_COINS] amounts);
    event ReceiveRen(uint256 renAmount);
    event Burn(uint256 burnAmount);

    constructor(ICurveExchange _exchange, address _curveTokenAddress, IGatewayRegistry _registry, IERC20[N_COINS] memory _coins) public {
        exchange = _exchange;
        registry = _registry;
        curveToken = IERC20(_curveTokenAddress);
        for(uint256 i = 0; i < N_COINS; i++) {
            coins[i] = _coins[i];
            require(coins[i].approve(address(exchange), uint256(-1)));
        }
        require(chi.approve(address(this), uint256(-1)));
    }

    function recoverStuck(
        bytes calldata encoded,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external {
        uint256 start = encoded.length - 32;
        address sender = abi.decode(encoded[start:], (address));
        require(sender == msgSender());
        bytes32 pHash = keccak256(encoded);
        uint256 mintedAmount = registry.getGatewayBySymbol("BTC").mint(pHash, _amount, _nHash, _sig);
        require(coins[0].transfer(msgSender(), mintedAmount));
    }
    
    function mintThenSwap(
        uint256 _minExchangeRate,
        uint256 _newMinExchangeRate,
        uint256 _slippage,
        int128 _j,
        address payable _coinDestination,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external discountCHI {
        //params is [_minExchangeRate, _slippage, _i, _j]
        //fail early so not to spend much gas?
        //require(_i <= 2 && _j <= 2 && _i != _j);
        // Mint renBTC tokens
        bytes32 pHash = keccak256(abi.encode(_minExchangeRate, _slippage, _j, _coinDestination, msgSender()));
        uint256 mintedAmount = registry.getGatewayBySymbol("BTC").mint(pHash, _amount, _nHash, _sig);
        
        // Get price
        // compare if the exchange rate now * slippage in BPS is what user submitted as
        uint256 dy = exchange.get_dy(0, _j, mintedAmount);
        uint256 rate = dy.mul(1e8).div(precisions_normalized[uint256(_j)]).div(mintedAmount);
        _slippage = uint256(1e4).sub(_slippage);
        uint256 min_dy = dy.mul(_slippage).div(1e4);
        
        // Price is OK
        if (rate >= _newMinExchangeRate) {
            require(_j != 0);
            doSwap(_j, mintedAmount, min_dy, _coinDestination);
        } else {
            //Send renBTC to the User instead
            require(coins[0].transfer(_coinDestination, mintedAmount));
            emit ReceiveRen(mintedAmount);
        }
    }

    function doSwap(int128 _j, uint256 _mintedAmount, uint256 _min_dy, address payable _coinDestination) internal {
        uint256 startBalance = coins[uint256(_j)].balanceOf(address(this));
        exchange.exchange(0, _j, _mintedAmount, _min_dy);
        uint256 endBalance = coins[uint256(_j)].balanceOf(address(this));
        uint256 bought = endBalance.sub(startBalance);
    
        //Send proceeds to the User
        require(coins[uint256(_j)].transfer(_coinDestination, bought));
        emit SwapReceived(_mintedAmount, bought, _j);
    }

    function mintThenDeposit(
        address payable _wbtcDestination, 
        uint256 _amount, 
        uint256[N_COINS] calldata _amounts, 
        uint256 _min_mint_amount, 
        uint256 _new_min_mint_amount, 
        bytes32 _nHash, 
        bytes calldata _sig
    ) external discountCHI {
        // Mint renBTC tokens
        bytes32 pHash = keccak256(abi.encode(_wbtcDestination, _amounts, _min_mint_amount, msgSender()));
        //use actual _amount the user sent
        uint256 mintedAmount = registry.getGatewayBySymbol("BTC").mint(pHash, _amount, _nHash, _sig);

        //set renBTC to actual minted amount in case the user sent less BTC to Ren
        uint256[N_COINS] memory receivedAmounts = _amounts;
        receivedAmounts[0] = mintedAmount;
        for(uint256 i = 1; i < N_COINS; i++) {
            receivedAmounts[i] = _amounts[i];
        }
        if(exchange.calc_token_amount(_amounts, true) >= _new_min_mint_amount) {
            doDeposit(receivedAmounts, mintedAmount, _new_min_mint_amount, _wbtcDestination);
        }
        else {
            require(coins[0].transfer(_wbtcDestination, mintedAmount));
            emit ReceiveRen(mintedAmount);
        }
    }

    function doDeposit(uint256[N_COINS] memory receivedAmounts, uint256 mintedAmount, uint256 _new_min_mint_amount, address _wbtcDestination) internal {
        for(uint256 i = 1; i < N_COINS; i++) {
            if(receivedAmounts[i] > 0) {
                require(coins[i].transferFrom(msgSender(), address(this), receivedAmounts[i]));
            }
        }
        uint256 curveBalanceBefore = curveToken.balanceOf(address(this));
        exchange.add_liquidity(receivedAmounts, 0);
        uint256 curveBalanceAfter = curveToken.balanceOf(address(this));
        uint256 curveAmount = curveBalanceAfter.sub(curveBalanceBefore);
        require(curveAmount >= _new_min_mint_amount);
        require(curveToken.transfer(_wbtcDestination, curveAmount));
        emit DepositMintedCurve(mintedAmount, curveAmount, receivedAmounts);
    }

    // function mintNoSwap(
    //     uint256 _minExchangeRate,
    //     uint256 _newMinExchangeRate,
    //     uint256 _slippage,
    //     int128 _j,
    //     address payable _wbtcDestination,
    //     uint256 _amount,
    //     bytes32 _nHash,
    //     bytes calldata _sig
    // ) external discountCHI {
    //     bytes32 pHash = keccak256(abi.encode(_minExchangeRate, _slippage, _j, _wbtcDestination, msgSender()));
    //     uint256 mintedAmount = registry.getGatewayBySymbol("BTC").mint(pHash, _amount, _nHash, _sig);
        
    //     require(coins[0].transfer(_wbtcDestination, mintedAmount));
    //     emit ReceiveRen(mintedAmount);
    // }

    // function mintNoDeposit(
    //     address payable _wbtcDestination, 
    //     uint256 _amount, 
    //     uint256[N_COINS] calldata _amounts, 
    //     uint256 _min_mint_amount, 
    //     uint256 _new_min_mint_amount, 
    //     bytes32 _nHash, 
    //     bytes calldata _sig
    // ) external discountCHI {
    //      // Mint renBTC tokens
    //     bytes32 pHash = keccak256(abi.encode(_wbtcDestination, _amounts, _min_mint_amount, msgSender()));
    //     //use actual _amount the user sent
    //     uint256 mintedAmount = registry.getGatewayBySymbol("BTC").mint(pHash, _amount, _nHash, _sig);

    //     require(coins[0].transfer(_wbtcDestination, mintedAmount));
    //     emit ReceiveRen(mintedAmount);
    // }

    function removeLiquidityThenBurn(bytes calldata _btcDestination, address _coinDestination, uint256 amount, uint256[N_COINS] calldata min_amounts) external discountCHI {
        uint256[N_COINS] memory balances;
        for(uint256 i = 0; i < coins.length; i++) {
            balances[i] = coins[i].balanceOf(address(this));
        }

        require(curveToken.transferFrom(msgSender(), address(this), amount));
        exchange.remove_liquidity(amount, min_amounts);

        for(uint256 i = 0; i < coins.length; i++) {
            balances[i] = coins[i].balanceOf(address(this)).sub(balances[i]);
            if(i == 0) continue;
            require(coins[i].transfer(_coinDestination, balances[i]));
        }

        // Burn and send proceeds to the User
        uint256 burnAmount = registry.getGatewayBySymbol("BTC").burn(_btcDestination, balances[0]);
        emit Burn(burnAmount);
    }

    function removeLiquidityImbalanceThenBurn(bytes calldata _btcDestination, address _coinDestination, uint256[N_COINS] calldata amounts, uint256 max_burn_amount) external discountCHI {
        uint256[N_COINS] memory balances;
        for(uint256 i = 0; i < coins.length; i++) {
            balances[i] = coins[i].balanceOf(address(this));
        }

        uint256 _tokens = curveToken.balanceOf(msgSender());
        if(_tokens > max_burn_amount) { 
            _tokens = max_burn_amount;
        }
        require(curveToken.transferFrom(msgSender(), address(this), _tokens));
        exchange.remove_liquidity_imbalance(amounts, max_burn_amount.mul(101).div(100));
        _tokens = curveToken.balanceOf(address(this));
        require(curveToken.transfer(_coinDestination, _tokens));

        for(uint256 i = 0; i < coins.length; i++) {
            balances[i] = coins[i].balanceOf(address(this)).sub(balances[i]);
            if(i == 0) continue;
            require(coins[i].transfer(_coinDestination, balances[i]));
        }

        // Burn and send proceeds to the User
        uint256 burnAmount = registry.getGatewayBySymbol("BTC").burn(_btcDestination, balances[0]);
        emit Burn(burnAmount);
    }

    //always removing in renBTC, else use normal method
    function removeLiquidityOneCoinThenBurn(bytes calldata _btcDestination, uint256 _token_amounts, uint256 min_amount, uint8 _i) external discountCHI {
        uint256 startRenbtcBalance = coins[0].balanceOf(address(this));
        require(curveToken.transferFrom(msgSender(), address(this), _token_amounts));
        exchange.remove_liquidity_one_coin(_token_amounts, _i, min_amount);
        uint256 endRenbtcBalance = coins[0].balanceOf(address(this));
        uint256 renbtcWithdrawn = endRenbtcBalance.sub(startRenbtcBalance);

        // Burn and send proceeds to the User
        uint256 burnAmount = registry.getGatewayBySymbol("BTC").burn(_btcDestination, renbtcWithdrawn);
        emit Burn(burnAmount);
    }
    
    function swapThenBurn(bytes calldata _btcDestination, uint256 _amount, uint256 _minRenbtcAmount, uint8 _i) external discountCHI {
        require(coins[_i].transferFrom(msgSender(), address(this), _amount));
        uint256 startRenbtcBalance = coins[0].balanceOf(address(this));
        exchange.exchange(_i, 0, _amount, _minRenbtcAmount);
        uint256 endRenbtcBalance = coins[0].balanceOf(address(this));
        uint256 renbtcBought = endRenbtcBalance.sub(startRenbtcBalance);
        
        // Burn and send proceeds to the User
        uint256 burnAmount = registry.getGatewayBySymbol("BTC").burn(_btcDestination, renbtcBought);
        emit Burn(burnAmount);
    }
}