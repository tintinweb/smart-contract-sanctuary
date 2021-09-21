/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// File: https://github.com/dapphub/ds-math/blob/master/src/math.sol

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.4.13;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// File: @0xcert/ethereum-erc721/src/contracts/tokens/erc721.sol


pragma solidity 0.8.0;

/**
 * @dev ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721
{

  /**
   * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
   * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
   * number of NFTs may be created and assigned without emitting Transfer. At the time of any
   * transfer, the approved address for that NFT (if any) is reset to none.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
   * address indicates there is no approved address. When a Transfer event emits, this also
   * indicates that the approved address for that NFT (if any) is reset to none.
   */
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
   * all NFTs of the owner.
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they mayb be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Set or reaffirm the approved address for an NFT.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved The new approved NFT controller.
   * @param _tokenId The NFT to approve.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice The contract MUST allow multiple operators per owner.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
   * invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId The NFT to find the approved address for.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

// File: @0xcert/ethereum-erc721/src/contracts/ownership/ownable.sol


pragma solidity 0.8.0;

/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable
{

  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



pragma solidity ^0.8.0;

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

// File: contracts/RobotoPlayerOne.sol


pragma solidity 0.8.0;





contract RobotoPlayerOne is IERC721Receiver, DSMath, Ownable {
    
    // Public Properties
    
    uint8   public nftCount;
    bool    public claimed;
    address public robotosContractAddress = 0x099689220846644F87D1137665CDED7BF3422747;
    
    // A running tally of how many attempts have been made to claim the hidden NFT.
    uint256 public claimAttempts;
    
    // The address of the person who held the winning Roboto!
    address public winnerAddress;
    
    // The address of the wallet who aped in and bought out the contract.
    address public buyoutClaimerAddress;
    
    // Constants
    
    uint256 public constant checkPrice = 0.02 ether;
    
    uint256 public constant buyoutPrice = 10 ether;
    
    // Private Properties
    
    // The number of the magic Roboto you need to claim this contract's prize.
    uint256 private winningRobotoIndex;
    
    // The prize NFT's number in its collection.
    // I used a tool to randomly pick a reply to this tweet: https://twitter.com/backseats_eth/status/1424860091375833096
    uint256 private prizeNftIndex;
    
    // The contract address of the prize NFT.
    address private externalContractAddress;
    
    // Withdraw Addresses
    
    address p1 = 0x3a6372B2013f9876a84761187d933DEe0653E377;
    address p2 = 0xef7639fADB98b76867cE29927B8347816C86A6eD;
    
    // Events
    
    event BuyoutOccurred(address _who);
    event FundsWithdrawn(string _str, uint256 _p1, uint256 _p2);
    event NftReceived();
    event NftCheck(address _checker, string _message);
    event TransferNFTToClaimer(address _keyHolder);
    event ValueReceived(address _from, uint256 _amount);
    
    // Constructor
    
    constructor(
        uint256 _winningRobotoIndex,
        uint256 _prizeNftIndex,
        address _externalContract
    ) {
        winningRobotoIndex = _winningRobotoIndex;
        prizeNftIndex = _prizeNftIndex;
        externalContractAddress = _externalContract;
        owner = msg.sender;
    }

    // IERC721Receiver Conformance Function

    // @dev: Attribute names not included below because I don't need them in my function's logic.
    function onERC721Received(address, address, uint256, bytes memory) public override returns(bytes4) {
        require(nftCount == 0, "Already holding NFT!");
        
        nftCount++;
        emit NftReceived();
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
    
    // Public Functions
    
    // @dev: At any time before being claimed, anyone can buy the mystery NFT from this contract for 10 ETH.
    function buyout() public payable {
        require(!claimed, "NFT has already been claimed!");
        require(msg.value == buyoutPrice, "Send 10 ETH.");
        
        emit BuyoutOccurred(msg.sender);
        buyoutClaimerAddress = msg.sender;
        _transfer();
    }

     // @dev: Function checks to see if your wallet holds the magic Roboto, costs 0.02 ETH.
     // If so, transfers; If not, emits event and returns false.
    function checkForKey() public payable returns (bool) {
        require(!claimed, "NFT has already been claimed!");
        require(msg.value == checkPrice, "Send 0.02 ETH");

        claimAttempts++;
        if (ERC721(robotosContractAddress).ownerOf(winningRobotoIndex) == msg.sender) {
            emit NftCheck(msg.sender, "is the key holder!");
            winnerAddress = msg.sender;
            _transfer();
            return true;
        }
        
        emit NftCheck(msg.sender, "was not the key holder");
        return false;
    }
    
    // @dev: Returns the balance of the contract.
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // Fallback Function

    // @dev: A fallback receive function in case random ETH is sent.
    receive() external payable {
        emit ValueReceived(msg.sender, msg.value);
    }
    
    // Private Function 

    // @dev: Tranfers the prize NFT stored in the contract and sets `claimed` to true, essentially ending the functionality of this contract.
    function _transfer() internal {
        emit TransferNFTToClaimer(msg.sender);
        ERC721(externalContractAddress).safeTransferFrom(address(this), msg.sender, prizeNftIndex);
        claimed = true;
        nftCount --;
    }
    
    // Ownable Function
    
    // @dev: Allows the owner of this contract to withdraw any funds accrued from usage.
    function returnFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 p1bal = wmul(balance, 0.9 ether);
        uint256 p2bal = wmul(balance, 0.1 ether);
        
        require(payable(p1).send(p1bal));
        require(payable(p2).send(p2bal));
        
        emit FundsWithdrawn("Paid:", p1bal, p2bal);
    }

}