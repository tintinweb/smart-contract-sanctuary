// SPDX-License-Identifier: MIT

/*
Join us at PolyCrystal.Finance!
█▀▀█ █▀▀█ █░░ █░░█ █▀▀ █▀▀█ █░░█ █▀▀ ▀▀█▀▀ █▀▀█ █░░ 
█░░█ █░░█ █░░ █▄▄█ █░░ █▄▄▀ █▄▄█ ▀▀█ ░░█░░ █▄▄█ █░░ 
█▀▀▀ ▀▀▀▀ ▀▀▀ ▄▄▄█ ▀▀▀ ▀░▀▀ ▄▄▄█ ▀▀▀ ░░▀░░ ▀░░▀ ▀▀▀
*/

import "./IPoolV1.sol";
import "./DowsingTokenV1.sol";
import "./Operators.sol";
import "./IERC20Metadata.sol";

pragma solidity ^0.8.6;

contract PoolDowserV1 is Operators {
    
    bytes32 constant public TOKEN_CODE_HASH = keccak256(type(DowsingTokenV1).creationCode);
    IPoolV1[] public pools;
    
    struct SymbolOverride {
        bytes short;
        bytes long;
    }

    mapping (IERC20 => SymbolOverride) public overrides;
    
    event AddPool(IPoolV1 pool);
    event RemovePool(IPoolV1 pool);
    
    //replaces instances of the token symbol with these when forming tracker token names/symbols.
    //Empty strings here clear a previous override and reset to the normal symbol
    function _override(IERC20 token, string memory _short, string memory _long) external onlyOwner {
        SymbolOverride storage tokenOverride = overrides[token];
        if (bytes(_short).length > 0) tokenOverride.short = bytes(_short);
        if (bytes(_long).length > 0) tokenOverride.long = bytes(_long);
    }
    
    function statusPrefix(IPoolV1 pool) public view returns (string memory prefix) {
        uint startBlock = pool.startBlock();
        if (block.number < startBlock) return unicode"✨";
        uint endBlock = pool.bonusEndBlock();
        if (block.number >= pool.bonusEndBlock()) return unicode"⛔"; 
        if (pool.rewardBalance() < uint(endBlock - block.number) * pool.rewardPerBlock()) return unicode"⚠️";
        else return "";
    }

    function shortSymbol(IERC20Metadata token) internal view returns (bytes memory symbol) {
        if (overrides[token].short.length == 0) {
            try token.symbol() returns (string memory _symbol) {
                return bytes(_symbol);
            } catch {
                return "";
            }
        } else {
            return overrides[token].short;
        }
    }
    function longSymbol(IERC20Metadata token) internal view returns (bytes memory symbol) {
        if (overrides[token].long.length == 0) {
            try token.symbol() returns (string memory _symbol) {
                return bytes(_symbol);
            } catch {
                return "";
            }
        } else {
            return overrides[token].long;
        }
    }
    
    //forms a string to represent user staked tokens for a pool
    function getNameStaked(IPoolV1 pool) external view returns (string memory name) {
        IERC20Metadata stakeToken = IERC20Metadata(address(pool.STAKE_TOKEN()));
        IERC20Metadata earnedToken = IERC20Metadata(address(pool.REWARD_TOKEN()));
        bytes memory stakeSymbol = longSymbol(stakeToken);
        bytes memory earnedSymbol = longSymbol(earnedToken);

        return string(abi.encodePacked(statusPrefix(pool), stakeSymbol, " staked to earn ", earnedSymbol));
    }
    //forms a string representing pending rewards for a pool
    function getNamePending(IPoolV1 pool) external view returns (string memory name) {
        IERC20Metadata stakeToken = IERC20Metadata(address(pool.STAKE_TOKEN()));
        IERC20Metadata earnedToken = IERC20Metadata(address(pool.REWARD_TOKEN()));
        bytes memory stakeSymbol = longSymbol(stakeToken);
        bytes memory earnedSymbol = longSymbol(earnedToken);

        return string(abi.encodePacked(statusPrefix(pool), earnedSymbol, " pending from staking ", stakeSymbol));
    }
    //forms a shorter string to represent user staked tokens for a pool
    function getSymbolStaked(IPoolV1 pool) external view returns (string memory name) {
        IERC20Metadata stakeToken = IERC20Metadata(address(pool.STAKE_TOKEN()));
        IERC20Metadata earnedToken = IERC20Metadata(address(pool.REWARD_TOKEN()));
        bytes memory stakeSymbol = shortSymbol(stakeToken);
        bytes memory earnedSymbol = shortSymbol(earnedToken);

        return string(abi.encodePacked(statusPrefix(pool), stakeSymbol, unicode"→", earnedSymbol));        
    }
    //forms a shorter string representing pending rewards for a pool
    function getSymbolPending(IPoolV1 pool) external view returns (string memory name) {
        IERC20Metadata stakeToken = IERC20Metadata(address(pool.STAKE_TOKEN()));
        IERC20Metadata earnedToken = IERC20Metadata(address(pool.REWARD_TOKEN()));
        bytes memory stakeSymbol = shortSymbol(stakeToken);
        bytes memory earnedSymbol = shortSymbol(earnedToken);

        return string(abi.encodePacked(statusPrefix(pool), unicode"⌛", earnedSymbol, " (", stakeSymbol, ")"));
    }
    
    function sweepToken(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
    
    function _addPool(IPoolV1 pool) internal {
        bytes memory code = type(DowsingTokenV1).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(false, pool));
        DowsingTokenV1 token;
        assembly {
            token := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(token)) { revert(0, 0) }
        }
        token.initialize(pool, false);
        salt = keccak256(abi.encodePacked(true, pool));
        assembly {
            token := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(token)) { revert(0, 0) }
        }
        token.initialize(pool, true);
        pools.push() = pool;
        emit AddPool(pool);
    }
    function addPool(IPoolV1 pool) external onlyOperator {
        _addPool(pool);
    }
    function addPools(IPoolV1[] calldata _pools) external onlyOperator {
        for (uint i; i < _pools.length; i++) {
            _addPool(_pools[i]);
        }
    }
    function findTokens(IPoolV1 pool) public view returns (DowsingTokenV1 stakedToken, DowsingTokenV1 pendingToken) {
        return (
            DowsingTokenV1(address(uint160(uint(keccak256(abi.encodePacked(hex'ff',address(this),keccak256(abi.encodePacked(false,pool)),TOKEN_CODE_HASH)))))),
            DowsingTokenV1(address(uint160(uint(keccak256(abi.encodePacked(hex'ff',address(this),keccak256(abi.encodePacked(true,pool)),TOKEN_CODE_HASH))))))
        );
    }
    function _destroy(IPoolV1 pool) internal {
        (DowsingTokenV1 staked, DowsingTokenV1 pending) = findTokens(pool);
        try staked.destroy() {} catch {}
        try pending.destroy() {} catch {}
        for (uint i; i < pools.length; i++) {
            if (pools[i] == pool) {
                pools[i] = pools[pools.length - 1];
                pools.pop();
            }
        }
        emit RemovePool(pool);
    }
    function update(address account) external {
        for (uint i; i < pools.length; i++) {
            (DowsingTokenV1 staked, DowsingTokenV1 pending) = findTokens(pools[i]);
            staked.update(account);
            pending.update(account);
        }
    }
    function update(address[] calldata accounts) external {
        for (uint i; i < pools.length; i++) {
            (DowsingTokenV1 staked, DowsingTokenV1 pending) = findTokens(pools[i]);
            for (uint j; j < accounts.length; j++) {
                staked.update(accounts[j]);
                pending.update(accounts[j]);
            }
        }
    }
    function destroy(IPoolV1 pool) external onlyOwner {
        _destroy(pool);
    }
    function destroyAll() external onlyOwner {
        for (uint i; i < pools.length; i++) {
            _destroy(pools[i]);
        }
        selfdestruct(payable(owner()));
    }

}