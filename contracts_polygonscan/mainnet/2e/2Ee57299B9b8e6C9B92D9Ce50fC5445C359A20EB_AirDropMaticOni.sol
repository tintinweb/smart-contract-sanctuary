// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";


contract AirDropMaticOni is Ownable {
    // Holder of the address of the person that received matic
    mapping(address => mapping(uint => address)) public nftAddressToNFTIdToOwnerThatReceivedTheMatic;

    // Verify that that nft already received matic
    mapping(address => mapping(uint => bool)) public nftAddressToNFTidToCheckIfReceivedMatic;

    // Remaining list of players that will receive matic.
    Player[] willReceiveMatic;

    // Amount of matic that we will be sending 
    uint public maticBeingSent = 1 ether;

    // Amount of players that will receive matic per call
    uint256 public BATCH_SIZE = 100;

    struct Player {
        address nftAddress;
        uint nftID;
        address ownerAddress;
    }

    struct NFTOwnership {
            address owner;
            uint id;
        }
    
    // Contract's Constructor
    /**
    * @notice Contract's constructor.
    */
    constructor() { }

    /**
    * @notice Set the amount of money to be sent to the players
    * @param _newValue new matic value to be sent.
    */
    function setMaticBeingSent(uint _newValue) external onlyOwner() {
        maticBeingSent = _newValue;
    }

    /**
    * @notice Set batch size of player that will receive matic.
    * @param _newValue New Batch size value.
    */
    function setBatchSize(uint _newValue) external onlyOwner() {
        BATCH_SIZE = _newValue;
    }

    /**
    * @notice Air drops matic to batch of 100 players or less everytime it is called
    */
    function airdropMatic() external onlyOwner() {
        uint256 batchSize = BATCH_SIZE;

        if(willReceiveMatic.length < BATCH_SIZE) {
            batchSize = willReceiveMatic.length;
        }

        for (uint256 lastPosition = willReceiveMatic.length; batchSize > 0; lastPosition--) {
            if(nftAddressToNFTidToCheckIfReceivedMatic[willReceiveMatic[lastPosition - 1].nftAddress][willReceiveMatic[lastPosition - 1].nftID] == true) {
                willReceiveMatic.pop();
            } else {
                // get address of receiver
                address _toMatic = willReceiveMatic[lastPosition - 1].ownerAddress;
                require(_toMatic != address(0), "Invalid addredd was set.");
                performTransfer(willReceiveMatic[lastPosition - 1].nftAddress, willReceiveMatic[lastPosition - 1].nftID, _toMatic);
            }
            batchSize = batchSize - 1;
        }
    }


    function performTransfer(address _nftAddress, uint _nftID, address _toMatic ) private onlyOwner() {
      require(nftAddressToNFTidToCheckIfReceivedMatic[_nftAddress][_nftID] == false, "This NFT Already received Matic.");
      // set that that nft already received matic
      nftAddressToNFTidToCheckIfReceivedMatic[_nftAddress][_nftID] = true;

      // set the address of the person that received the matic
      nftAddressToNFTIdToOwnerThatReceivedTheMatic[_nftAddress][_nftID] = _toMatic;

      // pop the nft from the list last position
      willReceiveMatic.pop();

      // sends the matic
      (bool success, ) = _toMatic.call{value: maticBeingSent}("");
      require(success, "Transfer failed.");
    }


    /**
    * @notice Sets/Maps the ownership of an NFT to some address in batches.
    * @param _contractAddresses NFT contract addresses in any blockchain
    * @param _nftIDS NFT IDs for that contract address.
    * @param _ownersAddresses owners addresses.
    */
    function updateNFTOwners(
        address[] memory _contractAddresses, 
        uint[] memory _nftIDS,
        address[] memory _ownersAddresses
    ) external onlyOwner() {
        require(
            _nftIDS.length == _ownersAddresses.length && 
            _contractAddresses.length == _ownersAddresses.length, 
            "Lists with not the same length"
            );
        for (uint i = 0; i < _nftIDS.length; i++) {
            nftAddressToNFTIdToOwnerThatReceivedTheMatic[_contractAddresses[i]][_nftIDS[i]] = _ownersAddresses[i];
            willReceiveMatic.push(Player(
                                        _contractAddresses[i],
                                        _nftIDS[i],
                                        _ownersAddresses[i]
                                        )
                                  );
        }
    }

    // Contract's Finance Functions
    /**
    * @notice Withdraw all contract matic to creator address.
    */
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdraw(owner(), balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /**
    * @notice Returns all the IDs with owner address for the following NFT.
    * @param _nftContract NFT contract Address.
    * @param _arraySize number of owners from 0 that you are requesting.
    */
    function getNFTsOwnershipData(
        address _nftContract,
        uint _arraySize
    ) external view returns (NFTOwnership[] memory) {
        NFTOwnership[] memory nftOwnershipArray = new NFTOwnership[](_arraySize);

        for (uint256 i = 0; i < _arraySize; i++) {
            nftOwnershipArray[i] = NFTOwnership(nftAddressToNFTIdToOwnerThatReceivedTheMatic[_nftContract][i], i);
        }
        return nftOwnershipArray;
    }


    /**
    * @notice Returns list of all remaining players that still did not received matic.
    */
    function getRemainPlayersToReceivematic()
        external
        view
        returns (Player[] memory)
    {
        require(willReceiveMatic.length > 0, "There are not more players to receive matic.");
        if(willReceiveMatic.length > 300) {
            Player[] memory players = new Player[](100);
            for (uint256 i = 0; i < 100 - 1; i++) {
                players[i] = willReceiveMatic[i];
            }
            return players;
        } else {
          Player[] memory players = new Player[](willReceiveMatic.length);

          for (uint256 i = 0; i < willReceiveMatic.length; i++) {
              players[i] = willReceiveMatic[i];
          }

          return players;
        }
    }

    /**
    * @notice returns this contract balance.
    */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
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