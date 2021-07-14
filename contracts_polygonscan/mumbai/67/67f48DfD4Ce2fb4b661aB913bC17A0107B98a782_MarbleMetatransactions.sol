/**
 *Submitted for verification at polygonscan.com on 2021-07-14
*/

// File: contracts/marble/MarbleNFT.sol


pragma solidity 0.6.2;


/// @dev Partial interface of the MarbleNFT contract so that we can easily work with it
abstract contract MarbleNFT {
  function forceApproval(uint256 _tokenId, address _approved) external virtual;
  function safeTransferFrom(address from, address to, uint256 tokenId) external virtual;
  function transferFrom(address from, address to, uint256 tokenId) external virtual;
}

// File: contracts/marble/MarbleBank.sol


pragma solidity 0.6.2;


/// @dev Partial interface of the MarbleBank contract so that we can easily work with it
abstract contract MarbleBank {
  function payByAffiliate(address token, uint256 amount, address from, address to, string calldata note) external virtual;
}

// File: contracts/marble/MarbleNFTCandidate.sol


pragma solidity 0.6.2;



/// @dev Partial interface of the MarbleNFTCandidate contract so that we can easily work with it
abstract contract MarbleNFTCandidate {
  MarbleBank public erc20Bank;
  function createCandidateWithERC20ForUser(string calldata _uri, address _erc20, address _owner) external virtual returns(uint256 index);
}

// File: contracts/marble/MarbleDutchAuction.sol


pragma solidity 0.6.2;


/// @dev Partial interface of the MarbleDutchAuction contract to easen our work with it
abstract contract MarbleDutchAuction {
  function createAuctionByMetatransaction(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _sender) external virtual;
  function bidByMetatransaction(uint256 _tokenId, uint256 _offer, address _offerBy) external virtual;
  function cancelAuctionByMetatransaction(uint256 _tokenId, address _sender) external virtual;
  function getCurrentPrice(uint256 _tokenId) external virtual view returns (uint256);
}

// File: contracts/marble/MarbleNFTFactory.sol


pragma solidity 0.6.2;





/// @dev Partial interface of the MarbleNFTFactory contract so that we can easily work with it
abstract contract MarbleNFTFactory {
  MarbleNFT public marbleNFTContract;
  MarbleNFTCandidate public marbleNFTCandidateContract;
  MarbleDutchAuction public marbleDutchAuctionContract;
}

// File: contracts/Ownable.sol


pragma solidity 0.6.2;


abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() 
      public
    {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @opengsn/gsn/contracts/interfaces/IRelayRecipient.sol

// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal virtual view returns (bytes memory);

    function versionRecipient() external virtual view returns (string memory);
}

// File: @opengsn/gsn/contracts/BaseRelayRecipient.sol

// SPDX-License-Identifier:MIT
// solhint-disable no-inline-assembly
pragma solidity ^0.6.2;


/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal override virtual view returns (bytes memory ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // we copy the msg.data , except the last 20 bytes (and update the total length)
            assembly {
                let ptr := mload(0x40)
                // copy only size-20 bytes
                let size := sub(calldatasize(),20)
                // structure RLP data as <offset> <length> <bytes>
                mstore(ptr, 0x20)
                mstore(add(ptr,32), size)
                calldatacopy(add(ptr,64), 0, size)
                return(ptr, add(size,64))
            }
        } else {
            return msg.data;
        }
    }
}

// File: contracts/MarbleMetatransactionsBase.sol


pragma solidity 0.6.2;




/// @title Base contract for all metatransaction contracts for Marble.Cards
abstract contract MarbleMetatransactionsBase is BaseRelayRecipient, Ownable {

  /// @notice Address of the marble nft factory contract
  MarbleNFTFactory public marbleNFTFactoryContract;

  /// @notice Sets the trusted forwarder which has permissions to execute functions on this contract
  /// @param _trustedForwarder Address of the trusted forwarder
  function setTrustedForwarder(address _trustedForwarder)
    external
    onlyOwner
  {
    trustedForwarder = _trustedForwarder;
  }

  /// @notice Get version of this metatransactions contract
  /// @return The version
  function versionRecipient() 
    override
    external 
    view
    returns (string memory) 
  {
    return "1";
  }

  /// @notice Sets the marble nft factory contract
  /// @dev Can be called only by the owner of this contract
  function setMarbleFactoryContract(MarbleNFTFactory _marbleNFTFactoryContract) 
    virtual
    external 
    onlyOwner 
  {
    marbleNFTFactoryContract = _marbleNFTFactoryContract;
  }

}

// File: contracts/MarbleAuctionMetatransactionsInterface.sol


pragma solidity 0.6.2;


/// @title Metatransactions support for auction contract of Marble.Cards
interface MarbleAuctionMetatransactionsInterface {

  /// @notice Puts the given NFT on auction If executed by the NFT owner
  /// @param nftId ID of the NFT token to be put on the auction
  /// @param startingPrice Initial price in the auction
  /// @param endingPrice Price at the end of the dynamic price phase of the auction and afterwards
  /// @param duration Duration of the dynamic price phase of the auction
  function startAuction(uint256 nftId, uint256 startingPrice, uint256 endingPrice, uint256 duration)
    external;

  /// @notice Bids on an NFT if it is in an auction
  /// @dev If the bid is high enough, the auction is immediatelly finished and the NFT transfered to the bidder
  /// @param nftId ID of the NFT to bid on
  /// @param offer Bid offer in MBC wei
  function bidAuction(uint256 nftId, uint256 offer)
    external;

  /// @notice Cancels auction on given NFT if issued by the owner and not in the first phase of the initial auction
  /// @param nftId ID of the NFT whose auction is to be canceled
  function cancelAuction(uint256 nftId) 
    external;

  /// @notice Gets current price (in MBC wei) of a given NFT in an auction
  /// @param nftId ID of the queried NFT
  function getAuctionCurrentPrice(uint256 nftId)
    external
    view
    returns(uint256);
  
}

// File: contracts/MarbleBankMetatransactionsInterface.sol


pragma solidity 0.6.2;


/// @title Metatransactions support for bank contract of Marble.Cards Dapp
interface MarbleBankMetatransactionsInterface {

  /// @notice Executes payment transaction on bank contract
  /// @dev The bank contract used is taken from the page candidate
  /// @param erc20Token Address of the token of the payment
  /// @param amount Amount of tokens t o be paid
  /// @param to Address to which the payment shold be sent
  /// @param note Note for the bank transaction
  function executeBankPayment(address erc20Token, uint256 amount, address to, string calldata note)
    external;

}

// File: contracts/MarbleCandidateMetatransactionsInterface.sol


pragma solidity 0.6.2;


/// @title Metatransactions support for candidate contract of Marble.Cards Dapp
interface MarbleCandidateMetatransactionsInterface
{

  /// @notice Creates page candidate using erc20 token for payment.
  /// @dev Creates page candidate using the given uri for the given user. The user needs to have enough tokens deposited in the erc20 bank which is used by the candidate contract.
  /// The full chain works as following:
  ///   ---> user A signs the transaction 
  ///   ---> relayer executes this method and extract address of A
  ///   ---> this method initiates candidate creation for A on the candidate contract (requires permission so it cannot be called by anyone and waste someone else's tokens)
  ///   ---> candidate contract issues payment to the bank contract (requires permission so it cannot be issued by anyone and waste someone else's tokens)
  ///   ---> if A has enough tokens in the bank, they are used to pay for the candidate creation (else it reverts)
  /// @param uri Uri of the candidate
  /// @param erc20Token Address of the token in which the candidate creation should be paid
  function createPageCandidateWithERC20(string calldata uri, address erc20Token) 
    external;

}

// File: contracts/MarbleNFTMetatransactionsInterface.sol


pragma solidity 0.6.2;


/// @title Metatransactions support for Marble.Card Dapp
/// @dev Since our original contracts do not support metatransactions, we have implemented this wrapper contract
interface MarbleNFTMetatransactionsInterface {

  /// @notice Transfer NFT to another address
  /// @dev Transfers nft from its current owner to new owner. This requires that this contract is admin of the NFT contract and that the signer owns the given token
  /// @param toAddress Address of the new owner of the NFT
  /// @param tokenId Id of the token to be transfered
  function transferNft(address toAddress, uint256 tokenId) 
    external;

}

// File: contracts/MarbleMetatransactionsInterface.sol


pragma solidity 0.6.2;







/// @title Metatransactions support for Marble.Card Dapp
/// @dev Since our original contracts do not support metatransactions, we have implemented this wrapper contract
interface MarbleMetatransactionsInterface is MarbleAuctionMetatransactionsInterface, 
  MarbleBankMetatransactionsInterface, MarbleCandidateMetatransactionsInterface, 
  MarbleNFTMetatransactionsInterface 
{

  /// @notice Sets the marble nft factory contract
  /// @dev Can be called only by the owner of this contract
  function setMarbleFactoryContract(MarbleNFTFactory _marbleNFTFactoryContract) 
    external;

}

// File: contracts/MarbleAuctionMetatransactions.sol


pragma solidity 0.6.2;




/// @title Metatransactions support for auction contract of Marble.Cards
contract MarbleAuctionMetatransactions is MarbleMetatransactionsBase, MarbleAuctionMetatransactionsInterface {

  /// @notice Puts the given NFT on auction If executed by the NFT owner
  /// @param nftId ID of the NFT token to be put on the auction
  /// @param startingPrice Initial price in the auction
  /// @param endingPrice Price at the end of the dynamic price phase of the auction and afterwards
  /// @param duration Duration of the dynamic price phase of the auction
  function startAuction(uint256 nftId, uint256 startingPrice, uint256 endingPrice, uint256 duration)
    override
    external
  {
    address issuer = _msgSender();
    marbleNFTFactoryContract.marbleDutchAuctionContract().createAuctionByMetatransaction(nftId, startingPrice, endingPrice, duration, issuer);
  }

  /// @notice Bids on an NFT if it is in an auction
  /// @dev If the bid is high enough, the auction is immediatelly finished and the NFT transfered to the bidder
  /// @param nftId ID of the NFT to bid on
  /// @param offer Bid offer in MBC wei
  function bidAuction(uint256 nftId, uint256 offer)
    override
    external
  {
    address issuer = _msgSender();
    marbleNFTFactoryContract.marbleDutchAuctionContract().bidByMetatransaction(nftId, offer, issuer);
  }

  /// @notice Cancels auction on given NFT if issued by the owner and not in the first phase of the initial auction
  /// @param nftId ID of the NFT whose auction is to be canceled
  function cancelAuction(uint256 nftId) 
    override
    external
  {
    address issuer = _msgSender();
    marbleNFTFactoryContract.marbleDutchAuctionContract().cancelAuctionByMetatransaction(nftId, issuer);
  }

  /// @notice Gets current price (in MBC wei) of a given NFT in an auction
  /// @param nftId ID of the queried NFT
  function getAuctionCurrentPrice(uint256 nftId)
    override
    external
    view
    returns(uint256)
  {
    return marbleNFTFactoryContract.marbleDutchAuctionContract().getCurrentPrice(nftId); 
  }

}

// File: contracts/MarbleBankMetatransactions.sol


pragma solidity 0.6.2;





/// @title Metatransactions support for bank contract of Marble.Cards Dapp
contract MarbleBankMetatransactions is MarbleMetatransactionsBase, MarbleBankMetatransactionsInterface {

  /// @notice Executes payment transaction on bank contract
  /// @dev The bank contract used is taken from the page candidate
  /// @param erc20Token Address of the token of the payment
  /// @param amount Amount of tokens t o be paid
  /// @param to Address to which the payment shold be sent
  /// @param note Note for the bank transaction
  function executeBankPayment(address erc20Token, uint256 amount, address to, string calldata note)
    override
    external
  {
    address sender = _msgSender();
    MarbleBank bank = marbleNFTFactoryContract.marbleNFTCandidateContract().erc20Bank();
    bank.payByAffiliate(erc20Token, amount, sender, to, note);
  }

}

// File: contracts/MarbleCandidateMetatransactions.sol


pragma solidity 0.6.2;




/// @title Metatransactions support for candidate contract of Marble.Cards Dapp
contract MarbleCandidateMetatransactions is MarbleMetatransactionsBase, MarbleCandidateMetatransactionsInterface
{
  
  /// @notice Creates page candidate using erc20 token for payment.
  /// @dev Creates page candidate using the given uri for the given user. The user needs to have enough tokens deposited in the erc20 bank which is used by the candidate contract.
  /// The full chain works as following:
  ///   ---> user A signs the transaction 
  ///   ---> relayer executes this method and extract address of A
  ///   ---> this method initiates candidate creation for A on the candidate contract (requires permission so it cannot be called by anyone and waste someone else's tokens)
  ///   ---> candidate contract issues payment to the bank contract (requires permission so it cannot be issued by anyone and waste someone else's tokens)
  ///   ---> if A has enough tokens in the bank, they are used to pay for the candidate creation (else it reverts)
  /// @param uri Uri of the candidate
  /// @param erc20Token Address of the token in which the candidate creation should be paid
  function createPageCandidateWithERC20(string calldata uri, address erc20Token) 
    override 
    external 
  {
    address issuer = _msgSender();
    marbleNFTFactoryContract.marbleNFTCandidateContract().createCandidateWithERC20ForUser(uri, erc20Token, issuer);
  }

}

// File: contracts/MarbleNFTMetatransactions.sol


pragma solidity 0.6.2;




/// @title Metatransactions support for Marble.Card Dapp
/// @dev Since our original contracts do not support metatransactions, we have implemented this wrapper contract. 
///   We also need to use custom Ownable contract, because Ownable from openzeppelin contains _msgSender function which 
///   clashes with the one from BaseRelayRecipient contract.
contract MarbleNFTMetatransactions is MarbleMetatransactionsBase, MarbleNFTMetatransactionsInterface {

  /// @notice Transfer NFT to another address
  /// @dev Transfers nft from its current owner to new owner. This requires that this contract is admin of the NFT contract and that the signer owns the given token
  /// @param toAddress Address of the new owner of the NFT
  /// @param tokenId Id of the token to be transfered
  function transferNft(address toAddress, uint256 tokenId) 
    override 
    external 
  {
    address issuer = _msgSender();
    marbleNFTFactoryContract.marbleNFTContract().forceApproval(tokenId, address(this));
    marbleNFTFactoryContract.marbleNFTContract().safeTransferFrom(issuer, toAddress, tokenId);
  }

}

// File: contracts/MarbleMetatransactions.sol


pragma solidity 0.6.2;










/// @title Metatransactions support for Marble.Card Dapp
/// @dev Since our original contracts do not support metatransactions, we have implemented this wrapper contract. 
///   We also need to use custom Ownable contract, because Ownable from openzeppelin contains _msgSender function which 
///   clashes with the one from BaseRelayRecipient contract.
contract MarbleMetatransactions is MarbleMetatransactionsBase, MarbleMetatransactionsInterface, 
  MarbleAuctionMetatransactions, MarbleBankMetatransactions, MarbleCandidateMetatransactions,
  MarbleNFTMetatransactions
{

  /// @param _trustedForwarder Address of the forwarder which we trust (has permissions to execute functions on this contract)
  /// @param _marbleNFTFactoryContract Address of the marble nft factory contract
  constructor(address _trustedForwarder, MarbleNFTFactory _marbleNFTFactoryContract)
    public
  {
    trustedForwarder = _trustedForwarder;
		marbleNFTFactoryContract = _marbleNFTFactoryContract;
	}

  /// @notice Sets the marble nft factory contract
  /// @dev Can be called only by the owner of this contract
  function setMarbleFactoryContract(MarbleNFTFactory _marbleNFTFactoryContract) 
    override(MarbleMetatransactionsBase, MarbleMetatransactionsInterface)
    external 
    onlyOwner 
  {
    marbleNFTFactoryContract = _marbleNFTFactoryContract;
  }

}