// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract LiquidityRestrictor is Ownable {
    struct Parameters {
        bool bypass;
        mapping(address => bool) isInitializer;
        mapping(address => uint256) startedAt;
        mapping(address => bool) isLocalAgent;
    }
    mapping(address => Parameters) public parameters;
    mapping(address => bool) public isTrustedAgent;

    event SetBypass(address indexed token, bool bypassed);
    event SetInitializer(address indexed token, address indexed who, bool isInitializer);
    event SetLocalAgent(address indexed token, address indexed who, bool isLocalAgent);
    event SetTrustedAgent(address indexed who, bool isTrustedAgent);
    event Started(address indexed token, address indexed pair, uint256 timestamp);

    function setParameters(
        address token,
        address[] memory initializers,
        address[] memory localAgents
    ) external onlyOwner {
        setInitializers(token, initializers, true);
        setLocalAgents(token, localAgents, true);
    }

    function setBypass(address token, bool bypass) external onlyOwner {
        parameters[token].bypass = bypass;
        emit SetBypass(token, bypass);
    }

    function setInitializers(
        address token,
        address[] memory who,
        bool isInitializer
    ) public onlyOwner {
        for (uint256 i = 0; i < who.length; i++) {
            parameters[token].isInitializer[who[i]] = isInitializer;
            emit SetInitializer(token, who[i], isInitializer);
        }
    }

    function setLocalAgents(
        address token,
        address[] memory who,
        bool isLocalAgent
    ) public onlyOwner {
        for (uint256 i = 0; i < who.length; i++) {
            parameters[token].isLocalAgent[who[i]] = isLocalAgent;
            emit SetLocalAgent(token, who[i], isLocalAgent);
        }
    }

    function setTrustedAgents(address[] memory who, bool isTrustedAgent_) external onlyOwner {
        for (uint256 i = 0; i < who.length; i++) {
            isTrustedAgent[who[i]] = isTrustedAgent_;
            emit SetTrustedAgent(who[i], isTrustedAgent_);
        }
    }

    function assureByAgent(
        address token,
        address from,
        address to
    ) external returns (bool allow, string memory message) {
        if (!(isTrustedAgent[msg.sender] || parameters[token].isLocalAgent[msg.sender]))
            return (false, 'LR: not agent');
        return _assureLiquidityRestrictions(token, from, to);
    }

    function assureLiquidityRestrictions(address from, address to)
        external
        returns (bool allow, string memory message)
    {
        return _assureLiquidityRestrictions(msg.sender, from, to);
    }

    function _assureLiquidityRestrictions(
        address token,
        address from,
        address to
    ) internal returns (bool allow, string memory message) {
        Parameters storage params = parameters[token];
        if (params.startedAt[to] > 0 || params.bypass || !checkPair(token, to)) return (true, '');
        if (!params.isInitializer[from]) return (false, 'LR: unauthorized');
        params.startedAt[to] = block.timestamp;
        emit Started(token, to, block.timestamp);
        return (true, 'start');
    }

    function checkPair(address token, address possiblyPair) public view returns (bool isPair) {
        try this._checkPair(token, possiblyPair) returns (bool value) {
            if (token == address(0)) return true;
            return value;
        } catch {
            return false;
        }
    }

    function _checkPair(address token, address possiblyPair) public view returns (bool isPair) {
        address token0 = IUniswapV2Pair(possiblyPair).token0();
        address token1 = IUniswapV2Pair(possiblyPair).token1();
        return token0 == token || token1 == token;
    }

    function seeRights(address token, address who)
        public
        view
        returns (
            bool isInitializer,
            bool isLocalAgent,
            bool isTrustedAgent_
        )
    {
        return (parameters[token].isInitializer[who], parameters[token].isLocalAgent[who], isTrustedAgent[who]);
    }

    function seeStart(address token, address pair) public view returns (uint256 startedAt) {
        return parameters[token].startedAt[pair];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}