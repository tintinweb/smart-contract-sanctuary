pragma solidity >=0.6.0 <0.7.0;

import "./interfaces/IDDP.sol";
import "./interfaces/IAllowList.sol";
import "./interfaces/ISecurityAssetToken.sol";
import "./OperatorVote.sol";
import "./templates/Initializable.sol";


contract MultiSignature is OperatorVote, Initializable {
    /// KYC address list
    address private _allowList;
    /// DDP contract address
    address private _ddp;
    /// Security Asset token contract address
    address private _sat;

    constructor (
        address[] memory founders,
        uint256 votesThreshold
        ) public OperatorVote(founders, votesThreshold)
    {
    }

    function configure(
        address allowList,
        address ddp,
        address sat
    ) external initializer
    {
        _allowList = allowList;
        _ddp = ddp;
        _sat = sat;
    }

    function allowAccount (address account) external onlyOperator {
        IAllowListChange(_allowList).allowAccount(account);
    }

    function disallowAccount(address account) external onlyOperator {
        IAllowListChange(_allowList).disallowAccount(account);
    }

    function mintSecurityAssetToken(
        address to,
        uint256 value,
        uint256 maturity) external onlyOperator
    {
        ISecurityAssetToken(_sat).mint(to, value, maturity);
    }

    function burnSecurityAssetToken(uint256 tokenId) external onlyOperator {
        ISecurityAssetToken(_sat).burn(tokenId);
    }

    function transferSecurityAssetToken(
        address from,
        address to,
        uint256 tokenId) external onlyOperator
    {
        ISecurityAssetToken(_sat).transferFrom(from, to, tokenId);
    }

    function setClaimPeriod(uint256 claimPeriod) external onlyOperator {
        IDDP(_ddp).setClaimPeriod(claimPeriod);
    }
}

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/GSN/Context.sol";


/**
 * @title OperatorVote contract
 * @dev Vote for operator address
 */
contract OperatorVote is Context {
    event AddedFounders(address[] founders);
    event OperatorChanged(address oldOperator, address newOperator);

    address private _operator;
    uint256 private _votesThreshold;

    mapping(address => bool) private _founders;
    mapping(address => address[]) private _candidates;

    constructor(address[] memory founders, uint256 votesThreshold) public {
        _votesThreshold = votesThreshold;

        for (uint256 i = 0; i < founders.length; i++) {
            _founders[founders[i]] = true;
        }

        address msgSender = _msgSender();
        _operator = msgSender;

        emit AddedFounders(founders);
        emit OperatorChanged(address(0), msgSender);
    }

    /**
     * @dev Throws out if the address is not the founder
     */
    modifier onlyFounders() {
        require(_founders[_msgSender()], "user is not a founder");
        _;
    }

    /**
     * @dev Throws if called by any account other than the operator.
     */
    modifier onlyOperator() {
        require(_msgSender() == _operator, "user is not the operator");
        _;
    }

    /**
     * @dev Get the number of votes for the operator
     * @param candidate address of operator candidate
     * @return number of votes
     */
    function getNumberVotes(address candidate) external view returns (uint256) {
        return _candidates[candidate].length;
    }

    /**
     * @dev Get the vote number threshold
     * @return votes threshold
     */
    function getThreshold() external view returns (uint256) {
        return _votesThreshold;
    }

    /**
     * @dev Returns current operator address.
     */
    function getOperator() external view returns (address) {
        return _operator;
    }

    /**
     * @dev Operator vote
     * @param candidate operator candidate address
     */
    function voteOperator(address candidate) external onlyFounders {
        require(candidate != address(0), "candidate is the zero address");

        address sender = _msgSender();

        for (uint256 i = 0; i < _candidates[candidate].length; i++) {
            require(
                _candidates[candidate][i] != sender,
                "you have already voted"
            );
        }

        if ((_candidates[candidate].length + 1) >= _votesThreshold) {
            delete _candidates[candidate];

            _operator = candidate;
            emit OperatorChanged(_operator, candidate);
        } else {
            _candidates[candidate].push(sender);
        }
    }
}

pragma solidity >=0.6.0 <0.7.0;

interface IAllowList {
    function isAllowedAccount(address account) external view returns (bool);
}

interface IAllowListChange {
    function allowAccount(address account) external;

    function disallowAccount(address account) external;
}

pragma solidity >=0.6.0 <0.7.0;

interface IDDP {
    function deposit(
        uint256 tokenId,
        uint256 value,
        uint256 maturity,
        address to
    ) external;

    function setClaimPeriod(uint256 claimPeriod) external;
}

pragma solidity >=0.6.0 <0.7.0;


/**
 * @title ISecurityAssetToken
 * @dev SecurityAssetToken interface
 */
interface ISecurityAssetToken {
    function mint(
        address to,
        uint256 value,
        uint256 maturity
    ) external;

    function burn(uint256 tokenId) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/GSN/Context.sol";


/**
 * @title Initializable allows to create initializable contracts
 * so that only deployer can initialize contract and only once
 */
contract Initializable is Context {
    bool private _isContractInitialized;
    address private _deployer;

    constructor() public {
        _deployer = _msgSender();
    }

    modifier initializer {
        require(_msgSender() == _deployer, "user not allowed to initialize");
        require(!_isContractInitialized, "contract already initialized");
        _;
        _isContractInitialized = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}