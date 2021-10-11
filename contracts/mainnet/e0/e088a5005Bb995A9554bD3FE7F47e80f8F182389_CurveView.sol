/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

pragma experimental ABIEncoderV2;




interface IAddressProvider {
    function admin() external view returns (address);
    function get_registry() external view returns (address);
    function get_address(uint256 _id) external view returns (address);
}




interface ISwaps {

    ///@notice Perform an exchange using the pool that offers the best rate
    ///@dev Prior to calling this function, the caller must approve
    ///        this contract to transfer `_amount` coins from `_from`
    ///        Does NOT check rates in factory-deployed pools
    ///@param _from Address of coin being sent
    ///@param _to Address of coin being received
    ///@param _amount Quantity of `_from` being sent
    ///@param _expected Minimum quantity of `_from` received
    ///        in order for the transaction to succeed
    ///@param _receiver Address to transfer the received tokens to
    ///@return uint256 Amount received
    function exchange_with_best_rate(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external payable returns (uint256);


    ///@notice Perform an exchange using a specific pool
    ///@dev Prior to calling this function, the caller must approve
    ///        this contract to transfer `_amount` coins from `_from`
    ///        Works for both regular and factory-deployed pools
    ///@param _pool Address of the pool to use for the swap
    ///@param _from Address of coin being sent
    ///@param _to Address of coin being received
    ///@param _amount Quantity of `_from` being sent
    ///@param _expected Minimum quantity of `_from` received
    ///        in order for the transaction to succeed
    ///@param _receiver Address to transfer the received tokens to
    ///@return uint256 Amount received
    function exchange(
        address _pool,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external payable returns (uint256);



    ///@notice Find the pool offering the best rate for a given swap.
    ///@dev Checks rates for regular and factory pools
    ///@param _from Address of coin being sent
    ///@param _to Address of coin being received
    ///@param _amount Quantity of `_from` being sent
    ///@param _exclude_pools A list of up to 8 addresses which shouldn't be returned
    ///@return Pool address, amount received
    function get_best_rate(
        address _from,
        address _to,
        uint256 _amount,
        address[8] memory _exclude_pools
    ) external view returns (address, uint256);


    ///@notice Get the current number of coins received in an exchange
    ///@dev Works for both regular and factory-deployed pools
    ///@param _pool Pool address
    ///@param _from Address of coin to be sent
    ///@param _to Address of coin to be received
    ///@param _amount Quantity of `_from` to be sent
    ///@return Quantity of `_to` to be received
    function get_exchange_amount(
        address _pool,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256);


    ///@notice Get the current number of coins required to receive the given amount in an exchange
    ///@param _pool Pool address
    ///@param _from Address of coin to be sent
    ///@param _to Address of coin to be received
    ///@param _amount Quantity of `_to` to be received
    ///@return Quantity of `_from` to be sent
    function get_input_amount(
        address _pool,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256);


    ///@notice Get the current number of coins required to receive the given amount in an exchange
    ///@param _pool Pool address
    ///@param _from Address of coin to be sent
    ///@param _to Address of coin to be received
    ///@param _amounts Quantity of `_to` to be received
    ///@return Quantity of `_from` to be sent
    function get_exchange_amounts(
        address _pool,
        address _from,
        address _to,
        uint256[] memory _amounts
    ) external view returns (uint256[] memory);


    ///@notice Set calculator contract
    ///@dev Used to calculate `get_dy` for a pool
    ///@param _pool Pool address
    ///@return `CurveCalc` address
    function get_calculator(address _pool) external view returns (address);
}




interface IRegistry {
    function get_lp_token(address) external view returns (address);
    function get_pool_from_lp_token(address) external view returns (address);
    function get_pool_name(address) external view returns(string memory);
    function get_coins(address) external view returns (address[8] memory);
    function get_underlying_coins(address) external view returns (address[8] memory);
    function get_decimals(address) external view returns (uint256[8] memory);
    function get_underlying_decimals(address) external view returns (uint256[8] memory);
    function get_balances(address) external view returns (uint256[8] memory);
    function get_underlying_balances(address) external view returns (uint256[8] memory);
    function get_virtual_price_from_lp_token(address) external view returns (uint256);
    function get_gauges(address) external view returns (address[10] memory, int128[10] memory);
    function pool_count() external view returns (uint256);
    function pool_list(uint256) external view returns (address);
}




interface IMinter {
    function mint(address _gaugeAddr) external;
    function mint_many(address[8] memory _gaugeAddrs) external;
}




interface IVotingEscrow {
    function create_lock(uint256 _amount, uint256 _unlockTime) external;
    function increase_amount(uint256 _amount) external;
    function increase_unlock_time(uint256 _unlockTime) external;
    function withdraw() external;
}




interface IFeeDistributor {
    function claim(address) external returns (uint256);
}









contract CurveHelper {
    address public constant CRV_TOKEN_ADDR = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant CRV_3CRV_TOKEN_ADDR = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    address public constant ADDRESS_PROVIDER_ADDR = 0x0000000022D53366457F9d5E68Ec105046FC4383;
    address public constant MINTER_ADDR = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    address public constant VOTING_ESCROW_ADDR = 0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2;
    address public constant FEE_DISTRIBUTOR_ADDR = 0xA464e6DCda8AC41e03616F95f4BC98a13b8922Dc;

    IAddressProvider public constant AddressProvider = IAddressProvider(ADDRESS_PROVIDER_ADDR);
    IMinter public constant Minter = IMinter(MINTER_ADDR);
    IVotingEscrow public constant VotingEscrow = IVotingEscrow(VOTING_ESCROW_ADDR);
    IFeeDistributor public constant FeeDistributor = IFeeDistributor(FEE_DISTRIBUTOR_ADDR);

    function getSwaps() internal view returns (ISwaps) {
        return ISwaps(AddressProvider.get_address(2));
    }

    function getRegistry() internal view returns (IRegistry) {
        return IRegistry(AddressProvider.get_registry());
    }
}




interface ILiquidityGauge {
    function lp_token() external view returns (address);
    function balanceOf(address) external view returns (uint256);
    
    function deposit(uint256 _amount, address _receiver) external;
    function approved_to_deposit(address _depositor, address _recipient) external view returns (bool);
    function set_approve_deposit(address _depositor, bool _canDeposit) external;

    function withdraw(uint256 _amount) external;
}





interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

contract CurveView is CurveHelper {
    struct LpBalance {
        address lpToken;
        uint256 balance;
    }

    function gaugeBalance(address _gaugeAddr, address _user) external view returns (uint256) {
        return ILiquidityGauge(_gaugeAddr).balanceOf(_user);
    }

    function curveDepositSig(uint256 _nCoins, bool _useUnderlying) external pure returns (bytes4) {
        if (!_useUnderlying) {
            if (_nCoins == 2) return bytes4(keccak256("add_liquidity(uint256[2],uint256)"));
            if (_nCoins == 3) return bytes4(keccak256("add_liquidity(uint256[3],uint256)"));
            if (_nCoins == 4) return bytes4(keccak256("add_liquidity(uint256[4],uint256)"));
            if (_nCoins == 5) return bytes4(keccak256("add_liquidity(uint256[5],uint256)"));
            if (_nCoins == 6) return bytes4(keccak256("add_liquidity(uint256[6],uint256)"));
            if (_nCoins == 7) return bytes4(keccak256("add_liquidity(uint256[7],uint256)"));
            if (_nCoins == 8) return bytes4(keccak256("add_liquidity(uint256[8],uint256)"));
            revert("Invalid number of coins in pool.");
        }
        if (_nCoins == 2) return bytes4(keccak256("add_liquidity(uint256[2],uint256,bool)"));
        if (_nCoins == 3) return bytes4(keccak256("add_liquidity(uint256[3],uint256,bool)"));
        if (_nCoins == 4) return bytes4(keccak256("add_liquidity(uint256[4],uint256,bool)"));
        if (_nCoins == 5) return bytes4(keccak256("add_liquidity(uint256[5],uint256,bool)"));
        if (_nCoins == 6) return bytes4(keccak256("add_liquidity(uint256[6],uint256,bool)"));
        if (_nCoins == 7) return bytes4(keccak256("add_liquidity(uint256[7],uint256,bool)"));
        if (_nCoins == 8) return bytes4(keccak256("add_liquidity(uint256[8],uint256,bool)"));
        revert("Invalid number of coins in pool.");
    }

    function curveWithdrawSig(uint256 _nCoins, bool _useUnderlying) external pure returns (bytes4) {
        if (!_useUnderlying) {
            if (_nCoins == 2) return bytes4(keccak256("remove_liquidity(uint256,uint256[2])"));
            if (_nCoins == 3) return bytes4(keccak256("remove_liquidity(uint256,uint256[3])"));
            if (_nCoins == 4) return bytes4(keccak256("remove_liquidity(uint256,uint256[4])"));
            if (_nCoins == 5) return bytes4(keccak256("remove_liquidity(uint256,uint256[5])"));
            if (_nCoins == 6) return bytes4(keccak256("remove_liquidity(uint256,uint256[6])"));
            if (_nCoins == 7) return bytes4(keccak256("remove_liquidity(uint256,uint256[7])"));
            if (_nCoins == 8) return bytes4(keccak256("remove_liquidity(uint256,uint256[8])"));
            revert("Invalid number of coins in pool.");
        }
        if (_nCoins == 2) return bytes4(keccak256("remove_liquidity(uint256,uint256[2],bool)"));
        if (_nCoins == 3) return bytes4(keccak256("remove_liquidity(uint256,uint256[3],bool)"));
        if (_nCoins == 4) return bytes4(keccak256("remove_liquidity(uint256,uint256[4],bool)"));
        if (_nCoins == 5) return bytes4(keccak256("remove_liquidity(uint256,uint256[5],bool)"));
        if (_nCoins == 6) return bytes4(keccak256("remove_liquidity(uint256,uint256[6],bool)"));
        if (_nCoins == 7) return bytes4(keccak256("remove_liquidity(uint256,uint256[7],bool)"));
        if (_nCoins == 8) return bytes4(keccak256("remove_liquidity(uint256,uint256[8],bool)"));
        revert("Invalid number of coins in pool.");
    }

    function curveWithdrawImbalanceSig(uint256 _nCoins, bool _useUnderlying) external pure returns (bytes4) {
        if (!_useUnderlying) {
            if (_nCoins == 2) return bytes4(keccak256("remove_liquidity_imbalance(uint256[2],uint256)"));
            if (_nCoins == 3) return bytes4(keccak256("remove_liquidity_imbalance(uint256[3],uint256)"));
            if (_nCoins == 4) return bytes4(keccak256("remove_liquidity_imbalance(uint256[4],uint256)"));
            if (_nCoins == 5) return bytes4(keccak256("remove_liquidity_imbalance(uint256[5],uint256)"));
            if (_nCoins == 6) return bytes4(keccak256("remove_liquidity_imbalance(uint256[6],uint256)"));
            if (_nCoins == 7) return bytes4(keccak256("remove_liquidity_imbalance(uint256[7],uint256)"));
            if (_nCoins == 8) return bytes4(keccak256("remove_liquidity_imbalance(uint256[8],uint256)"));
            revert("Invalid number of coins in pool.");
        }
        if (_nCoins == 2) return bytes4(keccak256("remove_liquidity_imbalance(uint256[2],uint256,bool)"));
        if (_nCoins == 3) return bytes4(keccak256("remove_liquidity_imbalance(uint256[3],uint256,bool)"));
        if (_nCoins == 4) return bytes4(keccak256("remove_liquidity_imbalance(uint256[4],uint256,bool)"));
        if (_nCoins == 5) return bytes4(keccak256("remove_liquidity_imbalance(uint256[5],uint256,bool)"));
        if (_nCoins == 6) return bytes4(keccak256("remove_liquidity_imbalance(uint256[6],uint256,bool)"));
        if (_nCoins == 7) return bytes4(keccak256("remove_liquidity_imbalance(uint256[7],uint256,bool)"));
        if (_nCoins == 8) return bytes4(keccak256("remove_liquidity_imbalance(uint256[8],uint256,bool)"));
        revert("Invalid number of coins in pool.");
    }

    function getPoolDataFromLpToken(address _lpToken) external view returns (
        uint256 virtualPrice,
        address pool,
        string memory poolName,
        address[8] memory tokens,
        uint256[8] memory decimals,
        uint256[8] memory balances,
        address[8] memory underlyingTokens,
        uint256[8] memory underlyingDecimals,
        uint256[8] memory underlyingBalances,
        address[10] memory gauges,
        int128[10] memory gaugeTypes
    ) {
        IRegistry Registry = getRegistry();
        virtualPrice = Registry.get_virtual_price_from_lp_token(_lpToken);
        pool = Registry.get_pool_from_lp_token(_lpToken);
        poolName = Registry.get_pool_name(pool);
        tokens = Registry.get_coins(pool);
        decimals = Registry.get_decimals(pool);
        balances = Registry.get_balances(pool);
        underlyingTokens = Registry.get_underlying_coins(pool);
        underlyingDecimals = Registry.get_underlying_decimals(pool);
        underlyingBalances = Registry.get_underlying_balances(pool);
        (gauges, gaugeTypes) = Registry.get_gauges(pool);
    }

    function getUserLP(
        address _user,
        uint256 _startIndex,
        uint256 _returnSize,
        uint256 _loopLimit
    ) external view returns (
        LpBalance[] memory lpBalances,
        uint256 nextIndex
    ) {
        lpBalances = new LpBalance[](_returnSize);
        IRegistry registry = getRegistry();
        uint256 listSize = registry.pool_count();
        
        uint256 nzCount = 0;
        uint256 index = _startIndex;
        for (uint256 i = 0; index < listSize && nzCount < _returnSize && i < _loopLimit; i++) {
            address pool = registry.pool_list(index++);
            address lpToken = registry.get_lp_token(pool);
            uint256 balance = IERC20(lpToken).balanceOf(_user);
            if (balance != 0) {
                lpBalances[nzCount++] = LpBalance(lpToken, balance);
            }
        }

        nextIndex = index < listSize ? index : 0;
    }
}