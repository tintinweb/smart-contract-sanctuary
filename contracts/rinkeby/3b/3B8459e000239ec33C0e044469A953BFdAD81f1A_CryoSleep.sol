/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: openzeppelin/[email protected]/Counters

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// Part: openzeppelin/openzepp[email protected]/IERC721Receiver

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: CryoSleep.sol

contract CryoSleep is
    IERC721Receiver
    {
    address public dummiezAddress;
    uint256 private CRYOSLEEP_PRICE = 2;
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _cryoCredits;

    event Freeze(address _operator, address _from, uint256 _tokenId);
    event Vend(address _from);

    constructor(address daddy) public IERC721Receiver() {
        dummiezAddress = daddy;
    }
  
    function onERC721Received(
        address operator, 
        address from, 
        uint256 tokenId, 
        bytes calldata data) external override returns (bytes4) {
        require(dummiezAddress == msg.sender);        
        emit Freeze(operator, from, tokenId);
        _cryoCredits[from].increment();
        return IERC721Receiver.onERC721Received.selector;
    } 

    function checkBalance() public view returns (uint256) {
       uint256 curbal = _cryoCredits[msg.sender].current();
       return curbal;
    }

    function vend() public {
        uint256 curbal = _cryoCredits[msg.sender].current();

        require(curbal >= 2, "Not enough juice.");
        _cryoCredits[msg.sender].decrement();
        _cryoCredits[msg.sender].decrement();
        emit Vend(msg.sender);

    }


       
}