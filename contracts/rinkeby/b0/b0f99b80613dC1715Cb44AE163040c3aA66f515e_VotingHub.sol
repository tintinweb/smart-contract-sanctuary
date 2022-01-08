// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";

import "VotingSession.sol";

contract VotingHub {
    string[] public votingSessionSymbols;
    mapping(string => address) public addressesOfVotingSessions;

    function createVotingSession(
        string memory symbol,
        uint256 start,
        uint256 end,
        uint8 numOfVotes
    ) public returns (address) {
        VotingSession newVotingSession = new VotingSession(
            symbol,
            start,
            end,
            numOfVotes
        );

        newVotingSession.transferOwnership(msg.sender);

        votingSessionSymbols.push(symbol);
        addressesOfVotingSessions[symbol] = address(newVotingSession);

        return address(newVotingSession);
    }

    function getAllVotinSessionsSymbols()
        public
        view
        returns (string[] memory)
    {
        return votingSessionSymbols;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";

import "VotingHub.sol";

contract VotingSession is Ownable {
    string public symbol;
    uint256 public start;
    uint256 public end;

    uint8 public numOfVotesPerUser;
    mapping(address => uint8) public votesPerUser;

    string[] public choices;
    // more efficient than array, when looking if it contains certain keys
    mapping(string => bool) public choicesMap;
    mapping(string => uint24) public votesPerChoice;

    constructor(
        string memory _symbol,
        uint256 _start,
        uint256 _end,
        uint8 _numOfVotesPerUser
    ) {
        require(
            _numOfVotesPerUser > 0,
            "Number of votes per user must be greater than 0."
        );

        symbol = _symbol;
        start = _start;
        end = _end;
        numOfVotesPerUser = _numOfVotesPerUser;
    }

    function getNumOfVotesForUser() public view returns (uint8) {
        return votesPerUser[msg.sender];
    }

    function vote(string memory choice, uint8 numberOfVotes) public {
        require(block.timestamp < end, "This voting session already ended.");
        require(
            block.timestamp >= start,
            "This voting session did not start yet."
        );
        require(choicesMap[choice], "Invalid choice.");
        require(
            votesPerUser[msg.sender] + numberOfVotes <= numOfVotesPerUser,
            "Exceeded number of votes per user."
        );

        votesPerUser[msg.sender] += numberOfVotes;
        votesPerChoice[choice] += numberOfVotes;
    }

    function addChoice(string memory choice) public onlyOwner {
        require(block.timestamp < end, "This voting session already ended.");
        require(
            block.timestamp < start,
            "This voting session already started."
        );
        choices.push(choice);
        choicesMap[choice] = true;
    }

    function getAllChoices() public view returns (string[] memory) {
        return choices;
    }

    function getResults() public view returns (string memory) {
        string memory results = "";
        for (uint256 i = 0; i < choices.length; i++) {
            results = append(
                results,
                choices[i],
                " => ",
                uint2str(votesPerChoice[choices[i]]),
                "\n"
            );
        }

        return results;
    }

    function append(
        string memory a,
        string memory b,
        string memory c,
        string memory d,
        string memory e
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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

/*
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