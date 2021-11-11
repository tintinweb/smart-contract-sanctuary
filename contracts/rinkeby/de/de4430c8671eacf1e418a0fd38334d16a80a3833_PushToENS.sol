// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./supportsENS.sol";

abstract contract ERC20 {
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
    function transfer(address to, uint tokens) virtual public returns (bool success);
}

abstract contract ERC721 {
    function transferFrom(address _from, address _to, uint256 _tokenId) virtual public;
}

contract PushToENS is SupportsENS {

  mapping(bytes32 => uint256) public balances;

  event Pushed(bytes32 nameHash, address tokenAddress, uint8 sendType, uint256 amount);
  event Pulled(bytes32 nameHash, address tokenAddress, uint8 sendType, uint256 amount);

  // PUSH FUNCTIONS

   /**
    * @dev Generic internal push functions
    */
  function _push (bytes32 hash, uint256 amount, address tokenAddress, uint8 sendType) internal {
    //prevent overflow
    require(balances[hash]+amount>balances[hash], "Not enough funds");

    //increase the balance
    balances[hash] += amount;

    // tell everyone about it
    emit Pushed(hash, tokenAddress, sendType, amount);
  }

   /**
    * @dev Pushes ether sent in transaction for an ENS name
    */
  function pushEther2ENS (bytes32 nameHash) public payable {
    _push(nameHash, msg.value, 0x0000000000000000000000000000000000000000, 0);
  }

   /**
    * @dev Pushes ether sent in transaction for a normal address
    */
  function pushEther2Ethadd (address ethAddress) public payable {
    _push(keccak256(abi.encode(ethAddress)), msg.value, 0x0000000000000000000000000000000000000000, 1);
  }

   /**
    * @dev Pushes any amount of a given token for an ENS address
    */
  function pushTokens2ENS (bytes32 nameHash, address tokenAddress, uint256 amount) public {
     // instantiate token
     ERC20 token = ERC20(tokenAddress);
     // transfer tokens
     require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
     // save
    _push(keccak256(abi.encode(nameHash,tokenAddress)), amount, tokenAddress, 2);
  }

   /**
    * @dev Pushes an single NFT for an ENS address
    */
   function pushNFT2ENS (bytes32 nameHash, address nftAddress, uint256 tokenId) public {
     // instantiate token
     ERC721 nft = ERC721(nftAddress);
     // transfer NFT
     nft.transferFrom(msg.sender, address(this), tokenId);
     // save
    _push(keccak256(abi.encode(nameHash, nftAddress, tokenId)), tokenId, nftAddress, 3);
  }


  // PULL FUNCTIONS

   /**
    * @dev Generic internal pull function
    */
  function _pull (bytes32 hash, uint256 amount, address tokenAddress, uint8 sendType) internal {
    //Checks
    require(balances[hash]>=amount, "Not enough funds");

    //Effects
    balances[hash]-=amount;

    // Interaction
    emit Pushed(hash, tokenAddress, sendType, amount);
  }

   /**
    * @dev Pulls ether for any valid ENS name. Can be called by anyone
    */
  function pullEther2ENS (bytes32 nameHash, uint256 amount) public {
      //generic pull
      _pull(nameHash, amount, 0x0000000000000000000000000000000000000000, 0);

      //Interaction
      // getSafeENSAddress prevents returning empty address
      sendValue(payable(getSafeENSAddress(nameHash)), amount);
  }

   /**
    * @dev Pulls ether for any ethereum address. Can be called by anyone
    */
  function pullEther2Ethadd (address payable ethAddress, uint256 amount) public {
      //generic pull
      _pull(keccak256(abi.encode(ethAddress)), amount, 0x0000000000000000000000000000000000000000, 1);

      //Interaction
      // getSafeENSAddress prevents returning empty address
      sendValue(payable(ethAddress), amount);
  }

   /**
    * @dev Pulls any amount of a given token to a valid ENS address. Can be called by anyone
    */
  function pullToken2ENS (bytes32 nameHash, address tokenAddress, uint256 amount) public {
       // instantiate token
     ERC20 token = ERC20(tokenAddress);

     //generic pull
      _pull(keccak256(abi.encode(nameHash,tokenAddress)), amount, tokenAddress, 2);

     // transfer tokens
     // getSafeENSAddress prevents returning empty address
     token.transfer(getSafeENSAddress(nameHash), amount);
  }

   /**
    * @dev Pulls one of any type of NFT to a valid ENS address. Can be called by anyone
    */
  function pullNFT2ENS (bytes32 nameHash, address nftAddress, uint256 tokenId) public {
       // instantiate token
     ERC721 NFT = ERC721(nftAddress);

     //generic pull
      _pull(keccak256(abi.encode(nameHash, nftAddress, tokenId)), tokenId, nftAddress, 3);

     // transfer tokens
     // getSafeENSAddress prevents returning empty address
     NFT.transferFrom(address(this), getSafeENSAddress(nameHash), tokenId);
  }

     /**
     * Open Zeppellin's Send Value
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}