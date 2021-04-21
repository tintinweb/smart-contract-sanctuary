// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./token/interfaces/FakeInterface.sol";
import "./interfaces/IBridgeManager.sol";
import "./interfaces/IPRIVIPodERC20Factory.sol";
import "./interfaces/IPRIVIPodERC721Factory.sol";
import "./interfaces/IPRIVIPodERC1155Factory.sol";
import "./interfaces/IPRIVIPodERC721RoyaltyFactory.sol";
import "./interfaces/IPRIVIPodERC1155RoyaltyFactory.sol";

/**
 * @title   SwapManager contract
 * @dev     Manages swaps and withdraws of Ether, ERC20 tokens, ERC721 tokens
 * and ERC1155 tokens between Ethereum and PRIVI blockchains
 * @author  PRIVI
 **/
contract SwapManager is AccessControl, ERC1155Holder {
  bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
  address private ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
  address public bridgeManagerAddress;
  address public erc20FactoryAddress;
  address public erc721FactoryAddress;
  address public erc1155FactoryAddress;
  address public erc721RoyaltyFactoryAddress;
  address public erc1155RoyaltyFactoryAddress;

  event DepositERC20Token(
    string indexed tokenSymbol,
    address from,
    uint256 amount
  );
  event WithdrawERC20Token(
    string indexed tokenSymbol,
    address to,
    uint256 amount
  );
  event DepositERC721Token(
    string indexed tokenSymbol,
    address from,
    uint256 tokenId
  );
  event WithdrawERC721Token(
    string indexed tokenSymbol,
    address to,
    uint256 tokenId
  );
  event DepositERC1155Token(
    string indexed tokenURI,
    address from,
    uint256 tokenId,
    uint256 amount
  );
  event WithdrawERC1155Token(
    string indexed tokenURI,
    address to,
    uint256 tokenId,
    uint256 amount
  );
  event BatchWithdrawERC1155Token(
    string indexed tokenURI,
    address to,
    uint256[] tokenIds,
    uint256[] amounts
  );
  event DepositEther(address indexed from, uint256 amount);
  event WithdrawEther(address indexed to, uint256 amount);

  /**
   * @notice Constructor to assign all roles to contract creator
   */
  constructor(
    address bridgeDeployedAddress,
    address erc20FactoryDeployedAddress,
    address erc721FactoryDeployedAddress,
    address erc1155FactoryDeployedAddress,
    address erc721FactoryRoyaltyDeployedAddress,
    address erc1155FactoryRoyaltyDeployedAddress
  ) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    // _setupRole(REGISTER_ROLE, _msgSender());
    _setupRole(TRANSFER_ROLE, _msgSender());
    bridgeManagerAddress = bridgeDeployedAddress;
    erc20FactoryAddress = erc20FactoryDeployedAddress;
    erc721FactoryAddress = erc721FactoryDeployedAddress;
    erc1155FactoryAddress = erc1155FactoryDeployedAddress;
    erc721RoyaltyFactoryAddress = erc721FactoryRoyaltyDeployedAddress;
    erc1155RoyaltyFactoryAddress = erc1155FactoryRoyaltyDeployedAddress;
  }

  // To be able to receive ERC1155 tokens (required if inheriting from AccessControl, ERC1155Holder)
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155Receiver, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @notice  Transfer ERC20 token from sender address (User) to contract address (PRIVI)
   * @dev     - Token to be transferred must be already registered
   *          - User has to approve first the amount to be transferred WITHIN the original ERC20 token contract,
   *          and not from this contract. Otherwise, transaction will always fail
   * @param   tokenSymbol Name of the token to be transferred
   * @param   amount Amount of tokens to be transferred
   */
  function depositERC20Token(string calldata tokenSymbol, uint256 amount)
    external
  {
    IBridgeManager bManager = IBridgeManager(bridgeManagerAddress);
    address tokenAddress = bManager.getErc20AddressRegistered(tokenSymbol);
    require(
      tokenAddress != ZERO_ADDRESS,
      "SwapManager: token is not registered into the platform"
    );
    require(
      IERC20(tokenAddress).allowance(_msgSender(), address(this)) >= amount,
      "SwapManager: token amount to be transferred to PRIVI is not yet approved by User"
    );
    IERC20(tokenAddress).transferFrom(_msgSender(), address(this), amount);
    emit DepositERC20Token(tokenSymbol, _msgSender(), amount);
  }

  /**
   * @notice  Transfer ERC20 token from contract address (PRIVI) to sender address (User)
   * @dev     - User must have TRANSFER_ROLE
   *          - PRIVI must have enough tokens to transfer them back to User
   * @param   tokenSymbol Name of the token to be transferred
   * @param   to Destination address to receive the tokens
   * @param   amount Amount of tokens to be transferred
   */
  function withdrawERC20Token(
    string calldata tokenSymbol,
    address to,
    uint256 amount
  ) external {
    require(amount > 0, "SwapManager: amount must be greater than 0");
    IBridgeManager bManager = IBridgeManager(bridgeManagerAddress);
    address tokenAddress = bManager.getErc20AddressRegistered(tokenSymbol);
    require(
      hasRole(TRANSFER_ROLE, _msgSender()),
      "SwapManager: must have TRANSFER_ROLE to withdraw token"
    );
    if (amount <= IERC20(tokenAddress).balanceOf(address(this))) {
      IERC20(tokenAddress).approve(address(this), amount);
      IERC20(tokenAddress).transferFrom(address(this), to, amount);
      emit WithdrawERC20Token(tokenSymbol, to, amount);
    } else if (
      IPRIVIPodERC20Factory(erc20FactoryAddress).getPodAddressBySymbol(
        tokenSymbol
      ) != ZERO_ADDRESS
    ) {
      IPRIVIPodERC20Factory(erc20FactoryAddress).mintPodTokenBySymbol(
        tokenSymbol,
        to,
        amount
      );
      emit WithdrawERC20Token(tokenSymbol, to, amount);
    } else {
      revert("SwapManager: cannot withdraw any amount");
      // only for testnet mint fake tokens
      // FakeInterface(tokenAddress).mintForUser(to, amount);
      // emit WithdrawERC20Token(tokenSymbol, to, amount);
    }
  }

  /**
   * @notice  Transfer ERC721 token from sender address (User) to contract address (PRIVI)
   * @dev     - User must have TRANSFER_ROLE
   *          - Token to be transferred must be already registered
   *          - User has to approve first the amount to be transferred WITHIN the original ERC721 token contract,
   *          and not from this contract. Otherwise, transaction will always fail
   * @param   tokenSymbol Name of the token to be transferred
   * @param   tokenId Token identifier to be transferred
   */
  function depositERC721Token(string calldata tokenSymbol, uint256 tokenId)
    external
  {
    IBridgeManager bManager = IBridgeManager(bridgeManagerAddress);
    address tokenAddress = bManager.getErc721AddressRegistered(tokenSymbol);
    require(
      tokenAddress != ZERO_ADDRESS,
      "SwapManager: token is not registered into the platform"
    );
    require(
      IERC721(tokenAddress).getApproved(tokenId) == address(this),
      "SwapManager: token to be transferred to PRIVI is not yet approved by User"
    );
    IERC721(tokenAddress).transferFrom(_msgSender(), address(this), tokenId);
    emit DepositERC721Token(tokenSymbol, _msgSender(), tokenId);
  }

  /**
   * @notice  Transfer ERC721 token from contract address (PRIVI) to sender address (User)
   * @dev     - User must have TRANSFER_ROLE
   *          - PRIVI must have enough tokens to transfer them back to User
   * @param   tokenSymbol Name of the token to be transferred
   * @param   to Destination address to receive the tokens
   * @param   tokenId Token identifier to be transferred
   * @param   isPodMint is it a withdraw from swap manager or is it minting new nft pod token
   */
  function withdrawERC721Token(
    string calldata tokenSymbol,
    address to,
    uint256 tokenId,
    bool isPodMint,
    bool isRoyalty
  ) external {
    IBridgeManager bManager = IBridgeManager(bridgeManagerAddress);
    address tokenAddress = bManager.getErc721AddressRegistered(tokenSymbol);
    require(
      hasRole(TRANSFER_ROLE, _msgSender()),
      "SwapManager: must have TRANSFER_ROLE to withdraw token"
    );
    if (isPodMint == true) {
      if (isRoyalty == true) {
        if (
          IPRIVIPodERC721RoyaltyFactory(erc721RoyaltyFactoryAddress)
            .getPodAddressBySymbol(tokenSymbol) != ZERO_ADDRESS
        ) {
          IPRIVIPodERC721RoyaltyFactory(erc721RoyaltyFactoryAddress)
            .mintPodTokenBySymbol(tokenSymbol, tokenId, to);
          emit WithdrawERC721Token(tokenSymbol, to, tokenId);
        } else {
          revert("SwapManager: cannot withdraw royalty token");
        }
      } else {
        if (
          IPRIVIPodERC721Factory(erc721FactoryAddress).getPodAddressBySymbol(
            tokenSymbol
          ) != ZERO_ADDRESS
        ) {
          IPRIVIPodERC721Factory(erc721FactoryAddress).mintPodTokenBySymbol(
            tokenSymbol,
            tokenId,
            to
          );
          emit WithdrawERC721Token(tokenSymbol, to, tokenId);
        } else {
          revert("SwapManager: cannot withdraw non royalty token");
        }
      }
    } else {
      if (IERC721(tokenAddress).ownerOf(tokenId) == address(this)) {
        IERC721(tokenAddress).transferFrom(address(this), to, tokenId);
        emit WithdrawERC721Token(tokenSymbol, to, tokenId);
      } else {
        revert("SwapManager: cannot withdraw non standard token");
      }
    }
  }

  /**
   * @notice  Transfer ERC1155 token from sender address (User) to contract address (PRIVI)
   * @dev     - User must have TRANSFER_ROLE
   *          - Token to be transferred must be already registered
   *          - User has to approve first the amount to be transferred WITHIN the original ERC1155 token contract,
   *          and not from this contract. Otherwise, transaction will always fail
   * @param   tokenURI Name of the token to be transferred
   * @param   tokenId Token identifier to be transferred
   */
  function depositERC1155Token(
    string calldata tokenURI,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) external {
    IBridgeManager bManager = IBridgeManager(bridgeManagerAddress);
    address tokenAddress = bManager.getErc1155AddressRegistered(tokenURI);
    require(
      tokenAddress != ZERO_ADDRESS,
      "SwapManager: token is not registered on BridgeManager"
    );
    require(
      IERC1155(tokenAddress).isApprovedForAll(msg.sender, address(this)) ==
        true,
      "SwapManager: user did not grant aprove yet"
    );
    IERC1155(tokenAddress).safeTransferFrom(
      _msgSender(),
      address(this),
      tokenId,
      amount,
      data
    );
    emit DepositERC1155Token(tokenURI, _msgSender(), tokenId, amount);
  }

  /**
   * @notice  Transfer ERC1155 token from contract address (PRIVI) to address (User)
   * @dev     - PRIVI must have enough tokens to transfer them to User
   *          or is has to be isPodMint.
   * @param   tokenURI Name of the token to be transferred
   * @param   to Destination address to receive the tokens
   * @param   tokenId Token identifier to be transferred
   * @param   amount Token amount to be transfered
   * @param   data bytes
   */
  function withdrawERC1155Token(
    string calldata tokenURI,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data,
    bool isPodMint,
    bool isRoyalty
  ) external {
    IBridgeManager bManager = IBridgeManager(bridgeManagerAddress);
    address tokenAddress = bManager.getErc1155AddressRegistered(tokenURI);
    require(
      hasRole(TRANSFER_ROLE, _msgSender()),
      "SwapManager: must have TRANSFER_ROLE to withdraw token"
    );
    if (isPodMint == true) {
      if (isRoyalty) {
        if (
          IPRIVIPodERC1155RoyaltyFactory(erc1155RoyaltyFactoryAddress)
            .getPodAddressByUri(tokenURI) != ZERO_ADDRESS
        ) {
          IPRIVIPodERC1155RoyaltyFactory(erc1155RoyaltyFactoryAddress).mintPodTokenByUri(
            tokenURI,
            to,
            tokenId,
            amount,
            data
          );
          emit WithdrawERC1155Token(tokenURI, to, tokenId, amount);
        } else {
          revert("SwapManager: cannot withdraw any amount (royalty)");
        }
      } else {
        if (
          IPRIVIPodERC1155Factory(erc1155FactoryAddress).getPodAddressByUri(
            tokenURI
          ) != ZERO_ADDRESS
        ) {
          IPRIVIPodERC1155Factory(erc1155FactoryAddress).mintPodTokenByUri(
            tokenURI,
            to,
            tokenId,
            amount,
            data
          );
          emit WithdrawERC1155Token(tokenURI, to, tokenId, amount);
        } else {
          revert("SwapManager: cannot withdraw any amount (non royalty)");
        }
      }
    } else {
      require(
        IERC1155(tokenAddress).balanceOf(address(this), tokenId) >= amount,
        "SwapManager: insufficient funds in PRIVI SwapManager"
      );
      IERC1155(tokenAddress).safeTransferFrom(
        address(this),
        to,
        tokenId,
        amount,
        data
      );
      emit WithdrawERC1155Token(tokenURI, to, tokenId, amount);
    }
  }

  /**
   * @notice  Batch Transfer ERC1155 token from contract address (PRIVI) to address (User)
   * @dev     - PRIVI must have enough tokens to transfer them to User
   *          or is has to be isPodMint.
   * @param   tokenURI Name of the token to be transferred
   * @param   to Destination address to receive the tokens
   * @param   tokenIds Token identifiers to be transferred
   * @param   amounts Token amounts to be transfered
   * @param   data bytes
   */
  function batchWithdrawERC1155Token(
    string calldata tokenURI,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory data,
    bool isPodMint
  ) external {
    IBridgeManager bManager = IBridgeManager(bridgeManagerAddress);
    address tokenAddress = bManager.getErc1155AddressRegistered(tokenURI);
    require(
      hasRole(TRANSFER_ROLE, _msgSender()),
      "SwapManager: must have TRANSFER_ROLE to withdraw token"
    );
    if (isPodMint == true) {
      if (
        IPRIVIPodERC1155Factory(erc1155FactoryAddress).getPodAddressByUri(
          tokenURI
        ) != ZERO_ADDRESS
      ) {
        IPRIVIPodERC1155Factory(erc1155FactoryAddress).batchMintPodTokenByUri(
          tokenURI,
          to,
          tokenIds,
          amounts,
          data
        );
        emit BatchWithdrawERC1155Token(tokenURI, to, tokenIds, amounts);
      } else {
        revert("SwapManager: cannot withdraw any amount");
      }
    } else {
      IERC1155(tokenAddress).safeBatchTransferFrom(
        address(this),
        to,
        tokenIds,
        amounts,
        data
      );
      emit BatchWithdrawERC1155Token(tokenURI, to, tokenIds, amounts);
    }
  }

  /**
   * @notice  Transfer ether from sender address to contract address
   * @dev     - Amount to be deposited must be greater than 0 ethers
   */
  function depositEther() external payable {
    require(msg.value > 0, "SwapManager: amount must be greater than 0 ethers");
    emit DepositEther(_msgSender(), msg.value);
  }

  /**
   * @notice  Transfer ether from contract address to sender address
   * @dev     - Sender must have TRANSFER_ROLE
   *          - Contract must have enough balance to do the transfer
   * @param   to Destination address to receive the ether
   * @param   amount Amount of ether to be transferred
   */
  function withdrawEther(address to, uint256 amount) external {
    require(
      hasRole(TRANSFER_ROLE, _msgSender()),
      "SwapManager: must have TRANSFER_ROLE to tranfer Eth"
    );
    require(
      payable(address(this)).balance >= amount,
      "SwapManager: not enough contract balance for the transfer"
    );

    address payable recipient = payable(to);

    if (amount <= address(this).balance) {
      recipient.transfer(amount);
    } else {
      IBridgeManager bManager = IBridgeManager(bridgeManagerAddress);
      address tokenAddress = bManager.getErc20AddressRegistered("WETH");
      require(
        tokenAddress != ZERO_ADDRESS,
        "SwapManager: WETH is not registered into the platform"
      );
      FakeInterface(tokenAddress).mintForUser(to, amount);
    }

    emit WithdrawEther(to, amount);
  }

  /**
   * @return  Contract balance in weis
   */
  function getBalance() external view returns (uint256) {
    return payable(address(this)).balance;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IBridgeManager {
  struct registeredToken {
    string name;
    string symbol;
    address deployedAddress;
  }

  /**
   * @notice get an address of a registered erc20 tokens
   */
  function getErc20AddressRegistered(string calldata tokenSymbol)
    external
    view
    returns (address returnAddress);

  /**
   * @notice get an array of all registered erc20 tokens
   */
  function getAllErc20Registered()
    external
    view
    returns (registeredToken[] memory);

  /**
   * @notice get count of all registered erc20 tokens
   */
  function getAllErc20Count() external view returns (uint256);

  /**
   * @notice get an address of a registered erc721 tokens
   */
  function getErc721AddressRegistered(string calldata tokenSymbol)
    external
    view
    returns (address returnAddress);

  /**
   * @notice get an array of all registered erc721 tokens
   */
  function getAllErc721Registered()
    external
    view
    returns (registeredToken[] memory);

  /**
   * @notice get count of all registered erc721 tokens
   */
  function getAllErc721Count() external view returns (uint256);

  /**
   * @notice get an address of a registered erc1155 tokens
   */
  function getErc1155AddressRegistered(string calldata tokenURI)
    external
    view
    returns (address returnAddress);

  /**
   * @notice get an array of all registered erc1155 tokens
   */
  function getAllErc1155Registered()
    external
    view
    returns (registeredToken[] memory);

  /**
   * @notice get count of all registered erc1155 tokens
   */
  function getAllErc1155Count() external view returns (uint256);

  /**
   * @notice  Register the contract address of an ERC20 Token
   * @dev     - Token name and address can't be already registered
   *          - Length of token name can't be higher than 25
   * @param   tokenName Name of the token to be registered (e.g.: DAI, UNI)
   * @param   tokenContractAddress Contract address of the ERC20 Token
   */
  function registerTokenERC20(
    string calldata tokenName,
    string calldata tokenSymbol,
    address tokenContractAddress
  ) external;

  /**
   * @notice  Register the contract address of an ERC721 Token
   * @dev     - Token name and address can't be already registered
   *          - Length of token name can't be higher than 25
   * @param   tokenName Name of the token to be registered
   * @param   tokenContractAddress Contract address of the ERC721 Token
   */
  function registerTokenERC721(
    string calldata tokenName,
    string calldata tokenSymbol,
    address tokenContractAddress
  ) external;

  /**
   * @notice  Register the contract address of an ERC1155 Token
   * @dev     - Token name and address can't be already registered
   *          - Length of token name can't be higher than 25
   * @param   tokenURI URI of the token to be registered
   * @param   tokenContractAddress Contract address of the ERC1155 Token
   */
  function registerTokenERC1155(
    string calldata tokenName,
    string calldata tokenURI,
    address tokenContractAddress
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPRIVIPodERC1155Factory {

  event PodCreated(string indexed uri, address podAddress);

  //TODO: getTotalTokenCreated()

  /**
   * @notice  Assigns `MODERATOR_ROLE` to SwapManager contract
   * @param   swapManagerAddress The SwapManager contract address
   */
  function assignRoleSwapManager(address swapManagerAddress) external;

  /**
   * @notice Returns the contract address of the Pod token
   * @param  uri The Pod URI
   * @return podAddress The contract address of the Pod token
   */
  function getPodAddressByUri(string calldata uri)
    external
    view
    returns (address podAddress);

  /**
   * @notice Returns the contract address of the Pod token
   * @param  podId The Pod Id
   * @return podAddress The contract address of the Pod token
   */
  function getPodAddressById(string calldata podId)
    external
    view
    returns (address podAddress);

  /**
   * @notice Creates an ERC1155 Pod token and registers it in the BridgeManager
   * @dev    - Pod id must not exist
   * @param  uri The base URI
   */
  function createPod(string calldata uri, string calldata podId)
    external
    returns (address podAddress);

  /**
   * @notice Mints ERC721 Pod tokens
   * @dev    - The caller must be MODERATOR_ROLE
   *         - `account` address can't be zero
   * @param  uri The base URI
   * @param  account The destination account to receive minted tokens
   * @param  tokenId The Pod token identifier
   * @param  amount The amount of tokens to be minted
   * @param  data The data to be added (currently not used)
   */
  function mintPodTokenByUri(
    string calldata uri,
    address account,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) external;

  /**
   * @dev Moderator will mint the amount of pod token for the investor"s account
   *
   * Requirements:
   *
   * - the caller must MODERATOR_ROLE to perform this action.
   */
  function mintPodTokenById(
    string calldata podId,
    address account,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) external;

  /**
   * @dev Moderator will mint the amount of pod token for the investor"s account
   *
   * Requirements:
   *
   * - the caller must MODERATOR_ROLE to perform this action.
   */
  function batchMintPodTokenByUri(
    string calldata uri,
    address account,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes calldata data
  ) external;

  /**
   * @dev Moderator will mint the amount of pod token for the investor"s account
   *
   * Requirements:
   *
   * - the caller must MODERATOR_ROLE to perform this action.
   */
  function batchMintPodTokenById(
    string calldata podId,
    address account,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPRIVIPodERC1155RoyaltyFactory {

  event PodCreated(string indexed uri, address podAddress);

  /**
   * @notice  Assigns `MODERATOR_ROLE` to SwapManager contract
   * @param   swapManagerAddress The SwapManager contract address
   */
  function assignRoleSwapManager(address swapManagerAddress) external;

  //TODO: getTotalTokenCreated()

  /**
   * @notice Returns the contract address of the Pod token
   * @param  uri The Pod URI
   * @return podAddress The contract address of the Pod token
   */
  function getPodAddressByUri(string calldata uri)
    external
    view
    returns (address podAddress);

  /**
   * @notice Returns the contract address of the Pod token
   * @param  podId The Pod Id
   * @return podAddress The contract address of the Pod token
   */
  function getPodAddressById(string calldata podId)
    external
    view
    returns (address podAddress);

  /**
   * @notice Creates a royalty ERC1155 Pod token and registers it in the BridgeManager
   * @dev    - Pod URI must not exist
   * @param  uri The base URI
   * @param  royaltyAmount The royalty amount to be transfer to the creator
   * @param  creator The Pod token creator
   * @return podAddress The contract address of the Pod token created
   */
  function createPod(
    string calldata uri,
    string calldata podId,
    uint256 royaltyAmount,
    address creator
  ) external returns (address podAddress);

  /**
   * @notice Creates a royalty ERC1155 Pod token generated by multiple 
   * creators and registers it in the BridgeManager
   * @dev    - Pod URI must not exist
   * @param  uri The base URI
   * @param  royaltyAmount The royalty amount to be transfer to the creator
   * @param  royaltyShares An array of royalty amounts to be shared to creators
   * @param  creators An array of Pod token creators to receive royalties
   * @return podAddress The contract address of the Pod token created
   */
  function createMultiCreatorPod(
    string calldata uri,
    string calldata podId,
    uint256 royaltyAmount,
    uint256[] memory royaltyShares,
    address[] memory creators
  ) external returns (address podAddress);

  /**
   * @notice Mints ERC1155 Pod tokens
   * @dev    - The caller must be MODERATOR_ROLE
   *         - destination address can't be zero
   *         - amount to be minted must be greater than zero
   * @param  uri The base URI
   * @param  account The destination account to receive minted tokens
   * @param  tokenId The Pod token identifier
   * @param  amount The amount of tokens to be minted
   * @param  data The data to be added (currently not used)
   */
  function mintPodTokenByUri(
    string calldata uri,
    address account,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) external;

  /**
   * @notice Mints ERC1155 Pod tokens
   * @dev    - The caller must be MODERATOR_ROLE
   *         - destination address can't be zero
   *         - amount to be minted must be greater than zero
   * @param  podId The Pod Id
   * @param  account The destination account to receive minted tokens
   * @param  tokenId The Pod token identifier
   * @param  amount The amount of tokens to be minted
   * @param  data The data to be added (currently not used)
   */
  function mintPodTokenById(
    string calldata podId,
    address account,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) external;

  /**
   * @notice Mints a batch of ERC1155 Pod tokens
   * @dev    - The caller must be MODERATOR_ROLE
   *         - destination address can't be zero
   *         - amount to be minted must be greater than zero
   * @param  uri The base URI
   * @param  account The destination account to receive minted tokens
   * @param  tokenIds An array of Pod token identifiers
   * @param  amounts An array of token amounts to be minted
   * @param  data The data to be added (currently not used)
   */
  function batchMintPodTokenByUri(
    string calldata uri,
    address account,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes calldata data
  ) external;

  /**
   * @notice Mints a batch of ERC1155 Pod tokens
   * @dev    - The caller must be MODERATOR_ROLE
   *         - destination address can't be zero
   *         - amount to be minted must be greater than zero
   * @param  podId The Pod Id
   * @param  account The destination account to receive minted tokens
   * @param  tokenIds An array of Pod token identifiers
   * @param  amounts An array of token amounts to be minted
   * @param  data The data to be added (currently not used)
   */
  function batchMintPodTokenById(
    string calldata podId,
    address account,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPRIVIPodERC20Factory {
  function getTotalTokenCreated() external view returns (uint256 totalPods);

  function getPodAddressById(string calldata podId)
    external
    view
    returns (address podAddress);

  function getPodAddressBySymbol(string calldata tokenSymbol)
    external
    view
    returns (address podAddress);

  /**
   *@dev only MODERATOR_ROLE role can create pods
   *
   * Requirements:
   *
   * - pod should not exist before.
   */
  function createPod(
    string calldata podId,
    string calldata podTokenName,
    string calldata podTokenSymbol
  ) external returns (address podAddress);

  /**
   * @dev Moderator will mint the amount of pod token for the investor's account
   *
   * Requirements:
   *
   * - the caller must MODERATOR_ROLE to perform this action.
   */
  function mintPodTokenById(
    string calldata podId,
    address account,
    uint256 investAmount
  ) external;

  function mintPodTokenBySymbol(
    string calldata tokenSymbol,
    address account,
    uint256 investAmount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPRIVIPodERC721Factory {

  event PodCreated(
    string indexed podId,
    string podTokenName,
    string podTokenSymbol
  );

  /**
   * @notice  Assigns `MODERATOR_ROLE` to SwapManager contract
   * @param   swapManagerAddress The SwapManager contract address
   */
  function assignRoleSwapManager(address swapManagerAddress) external;

  /**
   * @notice  Returns the total amount of Pod tokens created
   */
  function getTotalTokenCreated() external view returns (uint256 totalPods);

  /**
   * @notice Returns the contract address of the Pod token
   * @param  podId The Pod token identifier
   * @return podAddress The contract address of the Pod token
   */
  function getPodAddressById(string calldata podId)
    external
    view
    returns (address podAddress);

  /**
   * @notice Returns the contract address of the Pod token
   * @param  tokenSymbol The Pod token symbol (ticker)
   * @return podAddress The contract address of the Pod token
   */
  function getPodAddressBySymbol(string calldata tokenSymbol)
    external
    view
    returns (address podAddress);

  /**
   * @notice Creates an ERC721 Pod token and registers it in the BridgeManager
   * @dev    - Pod id must not exist
   *         - Pod name & symbol must not exist
   *         - Pod name & symbol can't be empty
   *         - Pod symbol can't be greater than 25 characters
   * @param  podId The Pod token identifier
   * @param  podTokenName The Pod token name
   * @param  podTokenSymbol The Pod token symbol (ticker)
   * @param  baseURI The base URI
   * @return podAddress The contract address of the Pod token created
   */
  function createPod(
    string calldata podId,
    string calldata podTokenName,
    string calldata podTokenSymbol,
    string calldata baseURI
  ) external returns (address podAddress);

  /**
   * @notice Mints ERC721 Pod tokens
   * @dev    - The caller must be MODERATOR_ROLE
   *         - `account` address can't be zero
   * @param  podId The Pod token identifier
   * @param  account The destination account to receive minted tokens
   */
  function mintPodTokenById(string calldata podId, uint256 tokenId, address account) external;

  /**
   * @notice Mints ERC721 Pod tokens
   * @dev    - The caller must be MODERATOR_ROLE
   *         - `account` address can't be zero
   * @param  tokenSymbol The Pod token symbol (sticker)
   * @param  account The destination account to receive minted tokens
   */
  function mintPodTokenBySymbol(string calldata tokenSymbol, uint256 tokenId, address account)
    external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPRIVIPodERC721RoyaltyFactory {

  event PodCreated(
    string indexed podId,
    string podTokenName,
    string podTokenSymbol
  );

  /**
   * @notice  Assigns `MODERATOR_ROLE` to SwapManager contract
   * @param   swapManagerAddress The SwapManager contract address
   */
  function assignRoleSwapManager(address swapManagerAddress) external;

  /**
   * @notice  Returns the total amount of Pod tokens created
   */
  function getTotalTokenCreated() external view returns (uint256 totalPods);

  /**
   * @notice Returns the contract address of the Pod token
   * @param  podId The Pod token identifier
   * @return podAddress The contract address of the Pod token
   */
  function getPodAddressById(string calldata podId)
    external
    view
    returns (address podAddress);

  /**
   * @notice Returns the contract address of the Pod token
   * @param  tokenSymbol The Pod token symbol (ticker)
   * @return podAddress The contract address of the Pod token
   */
  function getPodAddressBySymbol(string calldata tokenSymbol)
    external
    view
    returns (address podAddress);

  /**
   * @notice Creates a royalty ERC721 Pod token and registers it in the BridgeManager
   * @dev    - Pod id must not exist
   *         - Pod name & symbol must not exist
   *         - Pod name & symbol can't be empty
   *         - Pod symbol can't be greater than 25 characters
   * @param  podId The Pod token identifier
   * @param  podTokenName The Pod token name
   * @param  podTokenSymbol The Pod token symbol (ticker)
   * @param  baseURI The base URI
   * @param  royaltyAmount The royalty amount in percentage
   * @param  creator The Pod token creator to receive royalties
   * @return podAddress The contract address of the Pod token created
   */
  function createPod(
    string calldata podId,
    string calldata podTokenName,
    string calldata podTokenSymbol,
    string calldata baseURI,
    uint256 royaltyAmount,
    address creator
  ) external returns (address podAddress);

  /**
   * @notice Creates a royalty ERC721 Pod tokens generated by multiple 
   * creators and registers it in the BridgeManager
   * @dev    - Pod id must not exist
   *         - Pod name & symbol must not exist
   *         - Pod name & symbol can't be empty
   *         - Pod symbol can't be greater than 25 characters
   * @param  podId The Pod token identifier
   * @param  podTokenName The Pod token name
   * @param  podTokenSymbol The Pod token symbol (ticker)
   * @param  baseURI The base URI
   * @param  royaltyAmount The royalty amount in percentage
   * @param  royaltyShares An array of royalty amounts to be shared to creators
   * @param  creators An array of Pod token creators to receive royalties
   * @return podAddress The contract address of the Pod token created
   */
  function createMultiCreatorPod(
    string calldata podId,
    string calldata podTokenName,
    string calldata podTokenSymbol,
    string calldata baseURI,
    uint256 royaltyAmount,
    uint256[] memory royaltyShares,
    address[] memory creators
  ) external returns (address podAddress);

  /**
   * @notice Mints royalty ERC721 Pod tokens
   * @dev    - The caller must be MODERATOR_ROLE
   *         - `account` address can't be zero
   * @param  podId The Pod token identifier
   * @param  account The destination account to receive minted tokens
   */
  function mintPodTokenById(string calldata podId, uint256 tokenId, address account) external;

  /**
   * @notice Mints royalty ERC721 Pod tokens
   * @dev    - The caller must be MODERATOR_ROLE
   *         - `account` address can't be zero
   * @param  tokenSymbol The Pod token symbol (sticker)
   * @param  account The destination account to receive minted tokens
   */
  function mintPodTokenBySymbol(string calldata tokenSymbol, uint256 tokenId, address account)
    external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface FakeInterface {
  function mintForUser(address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 500
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}